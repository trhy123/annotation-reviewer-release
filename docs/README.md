# Documentation / 说明文档

- [中文操作手册](zh/00_操作手册.md)
- [English user manual](en/00_Annotation_Reviewer_User_Manual.md)


从项目根目录合并中文分册：

```text
python docs/build_manual.py --docs docs/zh --output "AnnotationReviewer操作手册.md"
```

Merge the English chapters from the project root:

```text
python docs/build_manual.py --docs docs/en --output "AnnotationReviewer_User_Manual.md"
```

未指定 `--docs` 时会交互询问分册目录；未指定 `--output` 时会询问输出路径，回车采用提示的默认文件名。找不到目录或编号分册时报错，不写入输出。分册目录内的图片等资源按需复制；目录外的项目文件直接链接到原文件，例如项目根目录的 `translations/zh_CN.json`，不另建 `_assets/_project` 副本。

Omitting `--docs` prompts for the chapter folder. Omitting `--output` prompts for the output path; Enter accepts the suggested filename. Missing folders or chapters report an error without writing output. Chapter-local assets may be copied; external project resources link to their original files, such as `translations/zh_CN.json` in the project root, without an `_assets/_project` copy.
