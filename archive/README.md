# My bash rc
   
## Introduction
This is a bashrc file that I personally use to make life easier and also to make terminal look better. Several commands depend on my local scripts, files etc. This is because currently this is the raw version (0.3 as of 4/14/17). This file **Only works on my computer**. Maybe it can be used as an example i try to comment things I do, this document also entails most of the features. I tried to make the code readable too.

This is for bash only, I know there are more costumizable options and preexisting amazingness like bash-it. But this is mostly personal, windows users SHOO!

Most code will be reproduced here, but there are a ton of comments in the .bashrc file. Whether or not this is independent of computers and all dependecies are mentioned under each feature.

### Getting this file on your computer 
```bash
$ git clone https://github.com/shreyasugemuge/bash
```
### Opening the bashrc
You dont have to use emacs, but Its really nice.
```bash
$ emacs PATH_TO_FOLDER/bash/.bashrc
```    
# Features

### Custom Prompt
#### Prompt what?
In case you are unsure about what a prompt is, what are you even doing here?
Prompt is the line that follows you with each command. Looks different on each system. often ends with $ for a normal user and a # for the root. The default bash prompt for terminal in mac looks something like this
   
![$](/img/def_term.png)

Just open terminal and you will see it. 
