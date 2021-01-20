# TiDB-Centos构建Debug环境



## 安装必要依赖

#### 安装golang环境
```
sudo yum install -y epel-release
 
sudo yum install -y golang
```


#### 安装Rust
```
sudo yum install -y gcc


curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

```


#### 安装Cargo
    ```
      [jan@jan pd]$ source $HOME/.cargo/env

      [jan@jan pd]$ cargo new hello-rust
    ```

## 安装VScode并配置Debug

## 编译PD
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

```

```

## 编译TiDB

## 编译TiKV

