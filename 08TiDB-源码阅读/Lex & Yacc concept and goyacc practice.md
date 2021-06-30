# Lex & Yacc concept and practice   
time: 2020-02-09   
TiDB 版本：4.0.9

## Summary

> - [The_concept_of_Lex_and_Yacc](#The_concept_of_Lex_and_Yacc)     
> - [The_example_of_goyacc](#The_example_of_goyacc)     
>   - [Impliment_of_goyacc](#Impliment_of_goyacc)     



## The_concept_of_Lex_and_Yacc  

 This part will introduce the basic knowledge about Lex & Yacc, reference from [Lex & yacc 's Document-Overview](http://dinosaur.compilertools.net/)

 - What does the compiler?  
   1. Read the source code and discover strcuture of it;  
   2. Process it from above to generate target programe as fragments;   
   3. The two step will individually working as their subtask by Lex and Yacc;    

 - What is Lex most processing?     
   Split the source file into tokens by Lex;   

 - What is Yacc most processing?   
   Find the hierarchical structure of the source code;   

## The_example_of_goyacc  

#### Impliment_of_goyacc   

```shell
# init case go project
go mod init lex_and_yacc_case

# install the goyacc from github  
go get -u github.com/golang/tools/tree/master/cmd/goyacc

# test result of install action
$ goyacc -h
Usage of goyacc:
  -l    disable line directives
  -o string
        parser output (default "y.go")
  -p string
        name prefix to use in generated code (default "yy")
  -v string
        create parsing tables (default "y.output")
```
   
## Reference_Blog

 - [TiDB源码阅读（二） 简单理解一下 Lex & Yacc](https://segmentfault.com/a/1190000023464340)   

 - [Lex与YACC详解](https://zhuanlan.zhihu.com/p/143867739)   

 - [Go实现自定义语言的基础 - goyacc简易入门](https://zhuanlan.zhihu.com/p/260180638)   