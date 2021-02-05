#!/bin/bash
## Author:SuperManito
## Modified:2021-2-5

## ============================================== 项 目 说 明 ==============================================
##                                                                                                        #
## 项目名称：《京东薅羊毛》一键部署 For Linux                                                                #
## 项目用途：通过参与京东商城的各种活动白嫖京豆                                                               #
## 适用系统：Ubuntu 16.04 ~ 20.10    Fedora 28 ~ 33                                                        #
##          Debian 9.0 ~ 10.7       CentOS 7.0 ~ 8.3                                                      #
## 温馨提示：尽量使用最新的稳定版系统，并且安装语言使用简体中文，CentOS如果是最小化安装，请通过SSH方式进入到终端   #
##                                                                                                        #
## 本人项目基于 Evine 公布的源码，活动脚本基于 lxk0301 大佬的 jd_scripts 项目                                 #
## 本人能力有限，这可能是最终版本，感谢 Evine 对此项目做出的贡献                                               #
## 核心活动脚本项目地址：https://gitee.com/lxk0301/jd_scripts/tree/master                                   #
##                                                                                                        #
## ========================================================================================================

## ======================================= 本 地 部 署 定 义 的 变 量 =======================================
## 安装目录
BASE="/root"
## 京东账户
COOKIE1='""'
COOKIE2='""'
COOKIE3='""'
COOKIE4='""'
COOKIE5='""'
COOKIE6='""'
##
## 配置京东账户注意事项：
## 1. 将 Cookie部分内容 填入"双引号"内，例 COOKIE1='"pt_key=xxxxxx;pt_pin=xxxxxx;"'
## 2. 本项目可同时运行无限个账号，从第7个账户开始需要自行在项目 config.sh 配置文件中定义变量例如Cookie7=""
## ========================================================================================================

## 环境判定：
function EnvJudgment() {
  ## 当前用户判定：
  if [ $UID -ne 0 ]; then
    echo -e '\033[31m ------------ Permission no enough, please use user ROOT! ------------ \033[0m'
    return
  fi
  ## 网络环境判定：
  ping -c 1 www.baidu.com >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "\033[31m ----- Network connection error.Please check the network environment and try again later! ----- \033[0m"
    return
  fi
}

## 系统判定：
function SystemJudgment() {
  ## 判定系统是基于Debian还是RedHat
  ls /etc | grep redhat-release -qw
  if [ $? -eq 0 ]; then
    SYSTEM="RedHat"
  else
    SYSTEM="Debian"
  fi
  ## 定义一些变量
  if [ $SYSTEM = "Debian" ]; then
    SYSTEM_NAME=$(lsb_release -is)
    SYSTEM_VERSION=$(lsb_release -cs)
    SYSTEM_VERSION_NUMBER=$(lsb_release -rs)
  elif [ $SYSTEM = "RedHat" ]; then
    SYSTEM_NAME=$(cat /etc/redhat-release | cut -c1-6)
    if [ $SYSTEM_NAME = "CentOS" ]; then
      SYSTEM_VERSION_NUMBER=$(cat /etc/redhat-release | cut -c22-24)
    elif [ $SYSTEM_NAME = "Fedora" ]; then
      SYSTEM_VERSION_NUMBER=$(cat /etc/redhat-release | cut -c16-18)
    fi
  fi
}

## 环境搭建：
function EnvStructures() {
  echo -e '\033[37m+---------------------------------------------------+ \033[0m'
  echo -e '\033[37m|                                                   | \033[0m'
  echo -e '\033[37m|   =============================================   | \033[0m'
  echo -e '\033[37m|                                                   | \033[0m'
  echo -e '\033[37m|      欢迎使用《京东薅羊毛》一键部署 For Linux     | \033[0m'
  echo -e '\033[37m|                                                   | \033[0m'
  echo -e '\033[37m|   =============================================   | \033[0m'
  echo -e '\033[37m|                                                   | \033[0m'
  echo -e '\033[37m+---------------------------------------------------+ \033[0m'
  sleep 3s
  ## CentOS安装扩展EPEL源并启用PowerTools仓库
  if [ $SYSTEM_NAME = "CentOS" ]; then
    yum install -y epel-release
    sed -i "s/enabled=0/enabled=1/g" /etc/yum.repos.d/CentOS-Linux-PowerTools.repo
    yum makecache
  fi
  ## 安装项目所需要的软件包
  if [ $SYSTEM = "Debian" ]; then
    apt remove -y nodejs npm >/dev/null 2>&1
    rm -rf /etc/apt/sources.list.d/nodesource.list >/dev/null 2>&1
    apt install -y git wget curl perl moreutils
    curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
    apt install -y nodejs npm
    apt autoremove -y
  elif [ $SYSTEM = "RedHat" ]; then
    yum remove -y nodejs npm >/dev/null 2>&1
    rm -rf /etc/yum.repos.d/nodesource-*.repo >/dev/null 2>&1
    yum install -y git wget curl perl moreutils
    curl -sL https://rpm.nodesource.com/setup_14.x | bash -
    yum install -y nodejs
  fi
}

## 项目部署：
function ProjectDeployment() {
  ## 备份之前Docker版本的配置文件
  ls /opt/jd | grep config -wq
  if [ $? -eq 0 ]; then
    cp /opt/jd/config/config.sh /opt/config.sh.bak
    cp /opt/jd/config/crontab.list /opt/crontab.list.bak
    rm -rf /opt/jd
  fi
  ## 下载源码并创建目录
  wget -P /opt https://github.com/SuperManito/JD-FreeFuck/releases/download/SourceCode/jd.tar.gz
  mkdir -p $BASE
  tar -zxvf /opt/jd.tar.gz -C $BASE
  rm -rf /opt/jd.tar.gz
  mkdir $BASE/config
  ## 创建项目配置文件
  cp $BASE/sample/config.sh.sample $BASE/config/config.sh
  ## 创建定时任务配置文件
  cp $BASE/sample/computer.list.sample $BASE/config/crontab.list
  ## 导入0301大佬gitee库活动脚本
  bash $BASE/git_pull.sh
  bash $BASE/git_pull.sh >/dev/null 2>&1
  ## 安装控制面板功能
  firewall-cmd --zone=public --add-port=5678/tcp --permanent
  systemctl reload firewalld
  cp $BASE/sample/auth.json $BASE/config/auth.json
  cd $BASE/panel
  npm install
  npm install -g pm2
  pm2 start server.js
  cd $BASE
}

## 更改配置文件：
function SetConfig() {
  sed -i "28c Cookie1=$COOKIE1" $BASE/config/config.sh
  sed -i "29c Cookie2=$COOKIE2" $BASE/config/config.sh
  sed -i "30c Cookie3=$COOKIE3" $BASE/config/config.sh
  sed -i "31c Cookie4=$COOKIE4" $BASE/config/config.sh
  sed -i "32c Cookie5=$COOKIE5" $BASE/config/config.sh
  sed -i "33c Cookie6=$COOKIE6" $BASE/config/config.sh
}

## 一键脚本：
function AutoScript() {
  ## 编写一键执行所有活动脚本：
  touch $BASE/run-all.sh
  bash $BASE/jd.sh | grep -o 'jd_[a-z].*' >$BASE/run-all.sh
  bash $BASE/jd.sh | grep -o 'jx_[a-z].*' >>$BASE/run-all.sh
  sed -i 's/^/bash jd.sh &/g' $BASE/run-all.sh
  sed -i 's/.js/ now/g' $BASE/run-all.sh
  sed -i '1i\#!/bin/bash' $BASE/run-all.sh
  cat $BASE/run-all.sh | grep jd_crazy_joy_coin -wq
  if [ $? -eq 0 ]; then
    sed -i "s/bash jd.sh jd_crazy_joy_coin.sh now//g" $BASE/run-all.sh
    sed -i '/^\s*$/d' $BASE/run-all.sh
    echo "bash jd.sh jd_crazy_joy_coin now" >>$BASE/run-all.sh
  fi
  ## 编写一键更新脚本：
  touch $BASE/manual-update.sh
  cat >$BASE/manual-update.sh <<EOF
#!/bin/bash
bash git_pull.sh
rm -rf run-all.sh
touch run-all.sh
bash jd.sh | grep -o 'jd_[a-z].*' >run-all.sh
bash jd.sh | grep -o 'jx_[a-z].*' >>run-all.sh
sed -i 's/^/bash jd.sh &/g' run-all.sh
sed -i 's/.js/ now/g' run-all.sh
sed -i '1i\#!/bin/bash' run-all.sh
cat run-all.sh | grep jd_crazy_joy_coin -wq
if [ $? -eq 0 ];then
  sed -i "s/bash jd.sh jd_crazy_joy_coin.sh now//g" run-all.sh
  sed -i '/^\s*$/d' run-all.sh
  echo "bash jd.sh jd_crazy_joy_coin now" >>run-all.sh
fi
EOF
}

#部署结果判定：
function ResultJudgment() {
  ls /opt | grep jd/config.sh.bak -wq
  if [ $? -eq 0 ]; then
    echo -e "\033[32m安装期间检测到旧版本项目文件，已备份旧的 config 与 crontab 配置文件至/opt目录，请不要覆盖现有配置文件...... \033[0m"
    sleep 3s
  fi
  VERIFICATION=$(node -v | cut -c2)
  if [ $VERIFICATION -eq "1" ]; then
    echo -e ''
    echo -e "\033[32m +------- 已 启 用 控 制 面 板 功 能 -------+ \033[0m"
    echo -e "\033[32m |                                          | \033[0m"
    echo -e "\033[32m | 本地访问：http://127.0.0.1:5678          | \033[0m"
    echo -e "\033[32m |                                          | \033[0m"
    echo -e "\033[32m | 外部访问：http://内部或外部IP地址:5678   | \033[0m"
    echo -e "\033[32m |                                          | \033[0m"
    echo -e "\033[32m | 初始用户名：admin，初始密码：adminadmin  | \033[0m"
    echo -e "\033[32m |                                          | \033[0m"
    echo -e "\033[32m +------------------------------------------+ \033[0m"
    echo -e ''
    sleep 3s
    echo -e "\033[32m --------------------- 一键部署成功，请执行 bash run-all.sh 命令开始你的薅羊毛行为 --------------------- \033[0m"
    echo -e "\033[32m +=====================================================================================================+ \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m | 定义：run-all.sh 为本人编写的一键执行所有活动脚本，manual-update.sh 为本人编写的一键更新脚本        | \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m |       如果想要单独执行或延迟执行特定活动脚本，请通过命令 bash jd.sh 查看教程                        | \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m | 注意：1. 本项目文件与一键脚本所在的目录为$BASE                                                      | \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m |       2. 为了保证脚本的正常运行，请不要更改任何组件的位置以避免出现未知的错误                       | \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m |       3. 手动执行 run-all 脚本后无需守在电脑旁，会在最后自动运行挂机活动脚本                        | \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    if [ $SYSTEM = "Debian" ]; then
      echo -e "\033[32m |       4. 执行 run-all 脚本期间如果卡住，可按回车键尝试或通过命令 Ctrl + Z 跳过继续执行剩余活动脚本  | \033[0m"
    elif [ $SYSTEM = "RedHat" ]; then
      echo -e "\033[32m |       4. 执行 run-all 脚本期间如果卡住，可按回车键尝试或通过命令 Ctrl + C 跳过继续执行剩余活动脚本  | \033[0m"
    fi
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m |       5. 由于京东活动一直变化可能会出现无法参加活动、报错等正常现象，可手动更新活动脚本             | \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m |       6. 如果需要更新活动脚本，请执行 bash manual-update.sh 命令进行一键更新即可                    | \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m |       7. 之前填入的 Cookie 部分内容具有一定的时效性，若提示失效请根据教程重新获取并通过命令手动更新 | \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m |       8. 我不是活动脚本的开发者，但后续使用遇到任何问题都可访问本项目寻求帮助，制作不易，理解万岁   | \033[0m"
    echo -e "\033[32m |                                                                                                     | \033[0m"
    echo -e "\033[32m +=====================================================================================================+ \033[0m"
    echo -e "\033[32m --------------------- 更多帮助请访问:  https://github.com/SuperManito/JD-FreeFuck --------------------- \033[0m"
    echo -e ''
    echo -e "\033[32m --------------------------------- 如果老板成功薅到羊毛，赏5毛钱可否OvO --------------------------------- \033[0m"
  else
    echo -e "\033[31m -------------- 一键部署失败 -------------- \033[0m"
    echo -e "\033[31m 原因：Nodejs未安装成功，请检查网络相关问题 \033[0m"
  fi
}

EnvJudgment
SystemJudgment
EnvStructures
ProjectDeployment
SetConfig
AutoScript
ResultJudgment
