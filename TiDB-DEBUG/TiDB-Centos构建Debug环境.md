# TiDB-Centos构建Debug环境

 - **注意**: 本文某些情况下，使用科学上网的方式访问外网;

## 安装必要依赖

#### 安装golang环境
```
[jan@jan ~]$ sudo yum install -y epel-release
 
[jan@jan ~]$ sudo yum install -y golang
```

#### 安装 glibc-2.18 

报错: /lib64/libc.so.6: version `GLIBC_2.18' not found 

```
curl -O http://ftp.gnu.org/gnu/glibc/glibc-2.18.tar.gz

tar zxf glibc-2.18.tar.gz 

cd glibc-2.18/

mkdir build

cd build/

../configure --prefix=/usr

sudo make -j2

sudo make install
```

#### 安装Rust
```
[jan@jan ~]$ sudo yum install -y gcc


[jan@jan ~]$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

```


#### 安装Cargo
    ```
      [jan@jan pd]$ source $HOME/.cargo/env

      [jan@jan pd]$ cargo new hello-rust
    ```

## 安装VScode并配置Debug

 - 开启断点功能   
  1. 文件 -> 首选项 -> 设置  
  2. 搜索 Allow setting breakpoints in any file，并勾选  



## 编译PD


```
git clone https://github.com/pingcap/pd
cd pd
make build

cd bin
nohup ./pd-server --data-dir=pd --log-file=pd.log &

telnet 127.0.0.1 2379
```

 - 修改hosts文件
   ```
    [jan@jan pd]$ sudo echo "199.232.28.133 raw.githubusercontent.com" > /etc/hosts

    [jan@jan pd]$ tail -1 /etc/hosts
      199.232.28.133 raw.githubusercontent.com
   ``` 
  - 测试cargo环境
   ```
    [jan@jan Desktop]$ cargo new hello-rust
     Created binary (application) `hello-rust` package

     [jan@jan Desktop]$ cd hello-rust/

     [jan@jan hello-rust]$ cargo run
      Finished dev [unoptimized + debuginfo] target(s) in 0.00s
      Running `target/debug/hello-rust`
      Hello, world!
   ```
- 编辑launch文件
   ```json
   {
   	"version": "0.2.0",
   	"configurations": [{
   			"name": "(Windows) Launch",
   			"type": "cppvsdbg",
   			"request": "launch",
   			"program": "${workspaceRoot}/target/debug/foo.exe",
   			"args": [],
   			"stopAtEntry": false,
   			"cwd": "${workspaceRoot}",
   			"environment": [],
   			"externalConsole": true
   		},
   		{
   			"name": "(OSX) Launch",
   			"type": "lldb",
   			"request": "launch",
   			"program": "${workspaceRoot}/target/debug/foo",
   			"args": [],
   			"cwd": "${workspaceRoot}",
   		}
   	]
   }
   ```

## 编译TiDB

## 编译TiKV

 - 
 ```
[jan@jan tikv]$ git clone https://github.com/tikv/tikv.git
[jan@jan tikv]$ pwd
/home/jan/Desktop/tikv/tikv

 ```









## 参考文章
 - [TiKV 源码解析 —— 调试环境搭建:http://www.iocoder.cn/TiKV/build-debugging-environment-second/](http://www.iocoder.cn/TiKV/build-debugging-environment-second/)  



