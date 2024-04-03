<div align=center>
  <img width=200 src="android\app\src\main\res\playstore-icon.png"  alt="图标"/>
  <h1 align="center">吊大助手</h1>
</div>

<div align=center>

一款改善你在CCZU的生活体验的应用😋

<img src="https://img.shields.io/badge/flutter-3+-blue" alt="Flutter">
  <img src="https://img.shields.io/badge/Rust-2021-brown" alt="Rust">
  <img src="https://img.shields.io/github/languages/code-size/CCZU-OSSA/cczu-helper?color=green" alt="size">
  <img src="https://img.shields.io/github/license/CCZU-OSSA/cczu-helper" alt="license">
</div>

## 为什么有这个

起源于吊大的打卡查询的应用，起初是自用的应用，后来觉得不如做好点发出来大家一起用，技术本身就是用来改善生活的，希望这个应用能让你在吊大更加便利~

[![图片](doc/screenshot.png)](https://github.com/CCZU-OSSA/cczu-helper/releases/latest)

## 平台支持

| Windows | Android | Linux | MacOS | IOS |
| ------- | ------- | ----- | ----- | --- |
| ✅       | ✅       | ❌     | ❌     | ❌   |

由于主要开发人员缺乏 Linux桌面环境 / Apple 设备，所以无法适配对应的版本，你可以尝试自行编译，如果平台对应的功能没有适配，欢迎提供Pull Request~

## 参与本项目

### 反馈意见

如果不知道如何在Github提issue，可以搜一下`如何提issue`

https://github.com/CCZU-OSSA/cczu-helper/issues

### 项目结构

- lib 存放Flutter代码
    - models 存放数据类型与一些常量还有一些用于沟通Rust和Flutter的代码
    - views 存放页面文件
    - controllers 存放配置文件的读取、页面更换等相关代码
    - messages 由rinf生成
  - message 存放用于生成沟通Rust与Flutter的proto文件
  - assets 存放应用资源文件
  - native 存放Rust代码(RINF)

### 如何编译

编译之前先确保你的设备上拥有 Rust 与 Flutter 环境，需要`clone`此项目你还需要一个`git`

然后运行以下代码

`<target-platform>`取决于你的目标平台

可以使用`flutter help build`命令查看

```sh
git clone https://github.com/CCZU-OSSA/cczu-helper.git
cd cczu-helper
cargo install rinf
rinf message
flutter build <target-platform> --release
```

## Using Rust Inside Flutter

This project leverages Flutter for GUI and Rust for the backend logic,
utilizing the capabilities of the
[Rinf](https://pub.dev/packages/rinf) framework.

To run and build this app, you need to have
[Flutter SDK](https://docs.flutter.dev/get-started/install)
and [Rust toolchain](https://www.rust-lang.org/tools/install)
installed on your system.
You can check that your system is ready with the commands below.
Note that all the Flutter subcomponents should be installed.

```bash
rustc --version
flutter doctor
```

You also need to have the CLI tool for Rinf ready.

```bash
cargo install rinf
```

Messages sent between Dart and Rust are implemented using Protobuf.
If you have newly cloned the project repository
or made changes to the `.proto` files in the `./messages` directory,
run the following command:

```bash
rinf message
```

Now you can run and build this app just like any other Flutter projects.

```bash
flutter run
```

For detailed instructions on writing Rust and Flutter together,
please refer to Rinf's [documentation](https://rinf.cunarist.com).

