# TiDB-TLS加密传输安全协议原理与应用
时间：2021-01-15

> - [非对称加密](#非对称加密)
> - [数字证书](#数字证书)
> - [TLS协议](#TLS协议)
> - [TiDB使用](#TiDB使用)
>    - [制作CA密钥和CA证书](#制作CA密钥和CA证书)
>    - [制作服务端密钥和证书](#制作服务端密钥和证书)
>    - [制作客户端密钥和证书](#制作客户端密钥和证书)
>    - [配置TiDB启用证书验证](#配置TiDB启用证书验证)

 - TLS (Transport Layer Security) 安全传输层协议是构建应用 TCP/IP 四层协议于应用层的传输协议，保证网络协议之间传输信息的安全性   

 ![TLS](https://img2018.cnblogs.com/blog/1769223/201910/1769223-20191019181046559-603567130.png)



## 非对称加密

 - 非对称加密通过公私钥实现
    - 公私钥关系：使用非对称密码算法可以生成公私钥；  
       - 公钥加密的的内容私钥可以解密，私钥加密的内容公钥可以解密；
       - 通过私钥计算得到公钥，但是通过公钥得不到私钥，因此通常情况是将公钥公开；

 - 非对称密码算法TLS两种使用场景  
    - 加解密；加解密用法用于TLS协议中的用户认证和对称加密算法协商，A用B的公钥加密传给B，只有B能用自己的私钥解密得到明文；
    - 数字签名：假如A使用自己的私钥加密数据，B得到这部分数据后，使用A的公钥进行解密得到明文，将明文和原始数据比对，发现一致，则可以证明是A使用自己的私钥签名的；  



## 数字证书

 - 数字证书的作用  
    - 证书中的数字签名可以验证是否拥有某一端（用户）公钥的私钥
 - 数字证书的构成
    - 证书是包含若干字段的文件
    - 证书中一般包含公钥、用户信息.....等
 - 数字证书的特性
    - 数字证书可以签发数字证书（如：将证书A签发（加密）为证书B）
        - Person1对证书A全部内容做hash，使用密钥对hash值加密得到证书B
        - Persion2可以使用Persion1的公钥解密验证证书签发者是否为Persion1
    - 根证书是特殊的证书，没有签发者，是绝对可信的证书

 - x.509 证书标准：数字认证证书有很多标准，x.509 就是比较通用的其中一种

 - x.509 证书内容
    - version：                  # 版本号
    - Serial Number:             # 序列号
    - Signature Algorithm：      # 加密算法
    - Validity:                  # 有效期
    - Subject:                   # 证书拥有者信息
    - Subject Public Key Info:   # 证书拥有者公钥信息
    - Signature Algorithm:       # 对证书正文取hash后，使用公钥加密的结果



## TLS协议

 - TLS协议使用对称加密和非对称加密通讯  
    - 用非对称加密确保获取的信息是可信客户端发来的信息    
    - 用对称加密保证传出过程中被加密的信息在不知道加密算法的情况下无法被破解    

 - 证书签发过程
 1. 生成客户端的密钥，即客户端的公私钥对，且要保证私钥只有客户端自己拥有。  
 2. 以客户端的公钥和客户端自身的信息(国家、机构、域名、邮箱等)为输入，生成证书请求文件  
    - 其中客户端的公钥和客户端信息是明文保存在证书请求文件中的  
    - 客户端私钥的作用是对客户端公钥及客户端信息做签名，自身是不包含在证书请求中的  
    - 然后把证书请求文件发送给 CA 机构，CA 使用私钥签发加密生成客户端证书来表明用户的身份  
       - CA机构接收到客户端的证书请求文件后，首先校验其签名  
       - 然后审核客户端的信息  
       - 最后CA机构使用自己的私钥为证书请求文件签名，生成证书文件，下发给客户端  



 - 具体通信过程
 1. 客户端向服务器 443 端口请求协定以后通讯的加密算法
     - CA 使用私钥加密服务器端的公钥、域名、公钥摘要生成密文（公钥、域名、公钥摘要=>密文）  
 2. 服务端收到客户端请求后，使用服务端私钥加密选中的通讯加密算法和 CA 证书得到的密文发送给客户端
     - 在 CA 加密后的密文上使用标注 CA 证书的签发者，发送给客户端端（密文 + CA 签发者名=>发往客户端端消息）
     - 客户端通过密文上标注的 CA 签发者，找到对应内置在客户端电脑中的公钥（此时如果中间拦截者，只能查看但是无法伪造内容给客户端，因为拦截者没有 CA 机构的私钥，只能使用公钥解密查看）  
 3. 客户端使用协定的对称加密算法加密信息得到密文向服务器 80/3306 端口发送请求  
     - 使用公钥破解获取的密文，得到服务器端的公钥、域名、公钥摘要（CA 私钥 + 密文=>公钥、域名、公钥摘要） 
 4. 客户端得到服务器端返回密文后，使用协定的对称加密算法解密从服务器得到的密文，一致通信下去  

![SSLTLS 传输协议原理.png](http://cdn.lifemini.cn/dbblog/20210115/fdf2c3ef163940d6a3b4d9103ca0575b.png)


## TiDB使用

#### 制作CA密钥和CA证书
```shell
# 安装openssl
sudo yum install openssl -y

# 使用 RSA 算法生成 2048 位 CA 私钥保存在 ca-key.pem
# 虽然 server-key.pem 文件的头尾都标注着“RSA PRIVATE KEY”，实际文件中包括了公钥和私钥,公钥和私钥总是成对儿出现
sudo openssl genrsa 2048 > ca-key.pem

# 基于 X509 标准使用 CA 密钥生成对应的 CA 证书保存在 ca-cert.pem
# 因为 ca-key.pem 是自签名的 CA 身份证，所以上面步骤中没有生成身份证申请文件（CSR）的过程，直接输出了 CA 证书
sudo openssl req -new -x509 -nodes -days 365000 -key ca-key.pem -out ca-cert.pem
```

#### 制作服务端密钥和证书
```shell
# 使用 RSA 算法生成 2048 位，有效期 365000 天的服务器端证书请求文件、服务器端未加密私钥 server-key.pem  
# 服务器端公钥和服务器端信息保存在证书请求文件 server-req.pem 中，服务器端公钥是从 server-key.pem 里提取出来的  
sudo openssl req -newkey rsa:2048 -days 365000 -nodes -out server-req.pem -keyout server-key.pem 

# 基于服务器端公私钥对 server-key.pem，使用 RSA 算法生成服务器端 RSA 私钥保存在 server-key.pem
sudo openssl rsa -in server-key.pem -out server-key.pem

# 基于 X509 标准使用 CA 私钥对服务器端证书请求文件 server-req.pem 加密，生成有效期365000天，序列号位 01 的服务端证书
# CA 机构首先校验签名，然后审核客户端的信息，最后使用 CA 私钥为证书请求文件签名，生成服务端证书文件 server-cert.pem
sudo openssl x509 -req -in server-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem
```

生成了服务器证书、服务器端私钥、服务器端公钥、通过CA私钥签发服务器端证书

#### 制作客户端密钥和证书
```shell
# 使用 RSA 算法生成 2048 位，有效期365000天的客户端密钥、客户端证书请求文件
sudo openssl req -newkey rsa:2048 -days 365000 -nodes -keyout client-key.pem -out client-req.pem

# 基于客户端密钥使用 RSA 算法进行再加密，生成客户端 RSA 私钥
sudo openssl rsa -in client-key.pem -out client-key.pem

# 基于 X509 标准使用客户端证书请求文件和 CA 私钥生成有效期365000天，序列号位01的客户端证书
sudo openssl x509 -req -in client-req.pem -days 365000 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem
```

#### 验证服务端和客户端证书
```shell
# 生成服务端和客户端证书之后，通过CA证书验证服务端证书、客户端证书
[tidb@tiup-tidb41 CA]$ openssl verify -CAfile ca-cert.pem server-cert.pem client-cert.pem
server-cert.pem: OK
client-cert.pem: OK

```
生成了客户端证书、客户端私钥、客户端公钥、通过CA私钥签发含有客户端证书的客户端证书


配置 TiDB 启用证书验证
```
[security]
ssl-cert ="path/to/server-cert.pem"
ssl-key ="path/to/server-key.pem"
ssl-ca="path/to/ca-cert.pem"
```
验证 TLS 安全配置生效
```
[tidb@tiup-tidb41 log]$ tail -20 tidb.log |grep secure 
[2021/01/15 09:30:13.356 -05:00] [INFO] [server.go:226] ["mysql protocol server secure connection is enabled"] ["client verification enabled"=true]


[tidb@tiup-tidb44 CA]$ mysql -uroot -h192.168.169.41 -P4000 --ssl-cert /home/tidb/CA/client-cert.pem --ssl-key /home/tidb/CA/client-key.pem --ssl-ca /home/tidb/CA/ca-cert.pem
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.25-TiDB-v4.0.9 TiDB Server (Apache License 2.0) Community Edition, MySQL 5.7 compatible

Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

```



## 参考文章

 - [liitdar的文章：https://blog.csdn.net/liitdar/article/details/80755073](https://blog.csdn.net/liitdar/article/details/80755073)

 - [一叶知秋的文章：https://www.cnblogs.com/struggle-1216/p/11704726.html](https://www.cnblogs.com/struggle-1216/p/11704726.html)