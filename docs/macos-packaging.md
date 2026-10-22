# macOS 绿色版打包、诊断与签名

## 目录与配置模式

`.app` 内包含 GUI、Python／Qt 依赖、嵌套 `DetectionWorker.app`、FFmpeg、FFprobe 和 libmpv。可执行程序位于 `Contents/MacOS` 与 `Contents/Helpers`，共享库位于 `Contents/Frameworks`，内置模板、Schema 和许可证位于 `Contents/Resources`。无需外置 runtime，也不向签名 Bundle 内写入用户配置。

绿色版 ZIP 同时提供 `.app` 同级的 `settings.ini`、`presets_detection/`、`models/`、`cache/` 和清理工具。两种运行方式如下：

| 使用方式 | 配置和相对路径基准 |
| --- | --- |
| 移动整个绿色版目录，同级存在 `settings.ini` | 优先读取同级配置；模型、预设、缓存和输出相对于绿色版目录 |
| 单独移动 `.app`，新位置无同级 `settings.ini` | 在 `~/Library/Application Support/AnnotationReviewer/` 初始化配置与可编辑预设 |

同级配置优先于已有的用户目录配置。显式配置的缓存路径优先；未指定时，系统模式使用 `~/Library/Caches/AnnotationReviewer/`。启动错误日志在绿色版目录内；系统模式使用 `~/Library/Logs/AnnotationReviewer/`。程序只按需建立模型或结果的目标目录，不附带模型权重和研究数据。

外部可编辑预设与 Bundle 内只读 Schema 分开。GUI 和嵌套 Worker 使用同一模式，不受启动工作目录影响。路径测试覆盖整目录搬迁、单独移动 `.app`、同级配置优先，以及 Windows/Linux 绿色版和 Nuitka standalone 路径；macOS Bundle 路径逻辑不用于其他平台。

未来安装版可把 `.app` 安装到 `/Applications` 并使用用户目录；当前绿色版未引入安装器或新的安装策略。

## 构建与验收

```bash
python packaging/build_release.py --target macos --arch arm64 --worker-flavor native --clean --archive
```

签名、公证和依赖验收集中在 `packaging/build_release.py`。构建完成后，会从无关工作目录检查真实 GUI 模块导入、Worker 的 `device_probe` JSON，以及 FFmpeg／FFprobe 和 libmpv 加载。已有绿色版也可单独检查，无需重新打包：

```bash
python packaging/build_release.py --validate-suite "/path/AnnotationReviewer.app"
```

该检查不创建主窗口，不等同于桌面验收。`--smoke-test` 仅检查入口，不能证明 GUI、视频或 OpenGL 可用。下载后仍需在实际 Mac 上检查 Finder 启动、Gatekeeper、播放、逐帧定位、CPU／MPS 检测、导出与保存。Linux 同样需要 Ubuntu 22.04／24.04 真实桌面验收，offscreen 测试不能替代此步骤。

在实际 Mac 上可继续检查系统版本、下载隔离属性和 LaunchServices 启动：

```bash
sw_vers
uname -m
spctl --assess --type execute -vv "/path/AnnotationReviewer.app"
xattr -p com.apple.quarantine "/path/AnnotationReviewer.app"
open -n "/path/AnnotationReviewer.app"
```

ad-hoc 测试包未获 Developer ID 信任时，Gatekeeper 拒绝属于签名状态问题，不能据此判定媒体代码加载失败。

主仓库只保留公共构建和 Release 同步工作流。公共构建中的源码测试与完整构建均由手动操作触发，不随 push 自动运行。测试 PR 中某个版本时，选择其分支和所需平台，保持 `publish_mode=none`。

发布目标选择 `source` 后，构建账号会触发自身仓库中的公共试用通道同步任务，不依赖源码账号的 Actions 额度。跨仓库构建需配置 `SOURCE_RELEASE_TOKEN`；公共仓库优先使用 `PUBLIC_RELEASE_TOKEN`，也可复用具有该公共仓库写权限的 `SOURCE_RELEASE_TOKEN`。同步始终从 `trhy123/annotation-reviewer` 读取对应版本，只复制文档、图标和校验通过的 Release 附件。

## 签名与公证

默认 ad-hoc 签名仅用于测试，不等同于 Apple 信任的 Developer ID 签名。正式分发需 Apple Developer Program 的有效证书和私钥。构建前设置：

```bash
export AR_MACOS_SIGN_IDENTITY="Developer ID Application: YOUR ORGANIZATION (TEAMID)"
python packaging/build_release.py --target macos --arch arm64 --worker-flavor native --clean --archive
```

构建脚本先完成所有 Bundle 修改，再由内向外签署 Mach-O、嵌套 Framework／App 和外层 App。正式公证使用本机 `notarytool` keychain profile，不在仓库保存凭据：

```bash
xcrun notarytool store-credentials "AR-NOTARY" \
  --apple-id "YOUR_APPLE_ID" --team-id "YOUR_TEAM_ID" --password "APP_SPECIFIC_PASSWORD"
python packaging/build_release.py \
  --notarize-app "/path/AnnotationReviewer.app" \
  --notary-profile "AR-NOTARY" \
  --notarized-archive "/path/AnnotationReviewer-notarized.zip"
```

脚本要求 Developer ID 签名，提交成功后 staple 并验证票据，再生成 ZIP。不要提交证书、私钥或 Apple token。支持目标为 macOS 13 或更新版本。

## 清理绿色版配置和缓存

先预览，再按需执行：

```bash
bash cleanup_macos.command --app "./AnnotationReviewer.app"
bash cleanup_macos.command --app "./AnnotationReviewer.app" --apply --reset-portable
```

实际删除需输入 `DELETE`。工具不删除 `.app`、模型、视频或检测结果；可编辑预设默认保留，只有显式传入 `--with-presets` 才纳入清理。
