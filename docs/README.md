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

`--docs` 必须指定源文件夹，找不到目录或编号分册时会报错并跳过，不写入输出。`--output` 可省略，默认在指定目录生成 `AnnotationReviewer_User_Manual.md`。

`--docs` is required. A missing folder or an empty chapter set reports an error without writing output. If `--output` is omitted, the result is `AnnotationReviewer_User_Manual.md` in the selected folder.
