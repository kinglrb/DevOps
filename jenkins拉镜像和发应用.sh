# ---------------------------------------拉取镜像和发布应用
# --------------Publish Over SSH 插件
# 配置远程服务器
# 拷贝公钥到远程服务器
ssh-copy-id 192.168.66.103
# jenkins系统配置->添加远程服务器

# jenkins配置远程调用
# 添加port参数
# 修改Jenkinsfile构建脚本
	# //gitlab的凭证
	def git_auth = "68f2087f-a034-4d39-a9ff-1f776dd3dfa8"
	# //构建版本的名称
	def tag = "latest"
	# //Harbor私服地址
	def harbor_url = "192.168.66.102:85"
	# //Harbor的项目名称
	def harbor_project_name = "tensquare"
	# //Harbor的凭证
	def harbor_auth = "ef499f29-f138-44dd-975e-ff1ca1d8c933"
	node {
		stage('拉取代码') {
			checkout([$class: 'GitSCM', branches: [[name: '*/${branch}']],doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [],userRemoteConfigs: [[credentialsId: "${git_auth}", url:'git@192.168.66.100:itheima_group/tensquare_back.git']]])
		}
		stage('代码审查') {
			def scannerHome = tool 'sonarqube-scanner'
			withSonarQubeEnv('sonarqube6.7.4') {
				sh """
					cd ${project_name}
					${scannerHome}/bin/sonar-scanner
				"""
			}
		}
		stage('编译，构建镜像，部署服务') {
			# //定义镜像名称
			def imageName = "${project_name}:${tag}"
			# //编译并安装公共工程
			sh "mvn -f tensquare_common clean install"
			# //编译，构建本地镜像
			sh "mvn -f ${project_name} clean package dockerfile:build"
			# //给镜像打标签
			sh "docker tag ${imageName} ${harbor_url}/${harbor_project_name}/${imageName}"
			# //登录Harbor，并上传镜像
			withCredentials([usernamePassword(credentialsId: "${harbor_auth}",passwordVariable: 'password', usernameVariable: 'username')]) {
				# //登录
				sh "docker login -u ${username} -p ${password} ${harbor_url}"
				# //上传镜像
				sh "docker push ${harbor_url}/${harbor_project_name}/${imageName}"
			}
			# //删除本地镜像
			sh "docker rmi -f ${imageName}"
			sh "docker rmi -f ${harbor_url}/${harbor_project_name}/${imageName}"
			# //远程调用，部署项目
			sshPublisher(publishers: [sshPublisherDesc(configName: 'master_server',transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand:"/opt/jenkins_shell/deploy.sh $harbor_url $harbor_project_name $project_name $tag $port", execTimeout: 120000, flatten: false, makeEmptyDirs: false,noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '',remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')],usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
		}
	}

# 部署脚本
vim deploy.sh
	#! /bin/sh
	#接收外部参数
	harbor_url=$1
	harbor_project_name=$2
	project_name=$3
	tag=$4
	port=$5
	imageName=$harbor_url/$harbor_project_name/$project_name:$tag
	echo "$imageName"
	#查询容器是否存在，存在则删除
	containerId=`docker ps -a | grep -w ${project_name}:${tag} | awk '{print $1}'`
	if [ "$containerId" != "" ] ; then
		#停掉容器
		docker stop $containerId
		#删除容器
		docker rm $containerId
		echo "成功删除容器"
	fi
	
	#查询镜像是否存在，存在则删除
	imageId=`docker images | grep -w $project_name | awk '{print $3}'`
	if [ "$imageId" != "" ] ; then
		#删除镜像
		docker rmi -f $imageId
		echo "成功删除镜像"
	fi
	
	# 登录Harbor私服
	docker login -u itcast -p Itcast123 $harbor_url
	# 下载镜像
	docker pull $imageName
	# 启动容器
	docker run -di -p $port:$port $imageName
	echo "容器启动成功"
# 上传deploy.sh
chmod +x deploy.sh
