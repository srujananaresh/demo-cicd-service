#!/usr/bin/env groovy

updateGitlabCommitStatus state: 'pending' // updates git lab commit status to pending

@Library('Jenkins-Pipeline-Library@master') _ // calls shared library
 
pipeline {

    environment {

        //read POM
        POM = readMavenPom file: 'pom.xml'
        appName = "${POM.artifactId}"
        appVersion = "${POM.version}"
        appGroup = "${POM.groupId}"

        ecrURL="https://942641012862.dkr.ecr.eu-central-1.amazonaws.com/iot-ecr"

    }

    options{
        gitLabConnection('GitLab@EIT')
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '25'))
    }

    tools{
        maven 'Maven 3.3.9'
    }       

    agent any

    stages{
        stage('Version Manager'){
            steps{
                script{
                    //VERSION MANAGER - version manager bumps the pom version on develop branch and removes snapshot for release branches
                    env.SKIP_BUILD="false"
                    checks.versionManager() //check versions and bump up
                    POMV2 = readMavenPom file: 'pom.xml' //read new pom
                    env.AppNewVersion = "${POMV2.version}"
                }
            }
        }  
        stage('Initiate'){
            when {
                expression { env.SKIP_BUILD == "false" }
            }
            steps{
                script{
                    parallel(
                            "Read Properties":{ //reads application properties to get server port
                                if (fileExists("env/DOCKER/application.properties")) {
                                    properties = readProperties file: "env/DOCKER/application.properties"
                                    env.APP_PORT = properties['server.port']
                                } else {
                                    log.error "Properties file do not exist! Please check! Exiting..."
                                    sh "exit 1"
                                }    
                            },
                            "Load Ansible":{ // load ansible scr
                                dir('ansible_scripts'){
                                    git branch: 'master', changelog: false, credentialsId: 'GITLAB_FUNC_USER',  poll: false, 
                                    url: 'http://gitlabce.tools.ci.vodafone.com/IOT/Ansible_Scripts.git'
                                }
                            }
                    )
                }
            }
        }
        stage('Build') { // build the project and perform unit testing // job fails in case a test fails
            when {
                expression { env.SKIP_BUILD == "false" }
            }
            steps{
                script{
                    updateGitlabCommitStatus state: 'running' // update git lab commit status
                    maven.buildWithConf "-U -B clean install" // build with maven, nexus connection and archive unit tests
                }
            }
        }
        stage('Code quality scan'){ // run quality scans
            when{
                expression{env.SKIP_BUILD == "false"} 
            }
            steps{
                script{
                    sonarQube.scanWithGoals "-Dsonar.exclusions=src/main/java/com/vodafone/iot/resourcesearch/response/pojo/**"
                    sonarQube.checkQualityGate '1'
                }
            }
        }
        stage('Inspect and Save Docker Image'){
            when{
                expression{env.SKIP_BUILD == "false"} 
            }
            steps{
                script{
                    dockerTests.inspectarchive "${appName}","${env.AppNewVersion}" //inspect container and save to have all the details if needed
                }
            }
        }
        stage('Smoke Test Docker image'){ //check process running within the container
            when{
                expression{env.SKIP_BUILD == "false"} 
            }
            steps{
                script{
                    docker.image("${appName}:${env.AppNewVersion}").withRun("--name ${appName}-${env.AppNewVersion} -p ${env.APP_PORT}:${env.APP_PORT} ") {
                      dockerTests.testProcess "${appName}","${env.AppNewVersion}"
                    }
                }
            }
        }
        stage('Build Package') { // run ansible task for package locally
            when{
                allOf {
                    anyOf{
                        branch 'develop'
                        branch 'release/*'
                    }
                    expression{env.SKIP_BUILD == "false" }
                }
            }
            steps{
                script{
                    sh "export ANSIBLE_CONFIG=ansible_scripts/ansible.cfg && " +
                       "ansible-playbook -i ansible_scripts/inventory/iot_inventory ansible_scripts/iot_playbook.yml " +
                       " --tags 'package' --extra-vars 'hst=local product='MS_Portal_2.0' path=${WORKSPACE} appName=${appName} appVersion=${env.AppNewVersion}' "

                    archiveArtifacts artifacts: '**.zip', fingerprint: true   
                }
            }
        }
        stage('Deployment'){
            when{
                allOf {
                    anyOf{
                        branch 'develop'
                        branch 'release/*'
                    }
                    expression{env.SKIP_BUILD == "false" }
             }
            }
            steps{
                script{
                    try{
                        //push image to AWS registry
                        docker.withRegistry("${ecrURL}", 'ecr:eu-central-1:ecr-credentials') {
                            docker.image("${appName}:${env.AppNewVersion}").push()
                            slackNotifier.sendMsgPortal "ci_cd_bckend_pipeline" , "${env.BUILD_URL} Image ${appName}:${env.AppNewVersion} pushed to ECR !", "good"    
                            if( env.BRANCH_NAME.startsWith("release") ){
                                log.info "Pushing image as latest..."
                                docker.image("${appName}:${env.AppNewVersion}").push("latest")
                                slackNotifier.sendMsgPortal "ci_cd_bckend_pipeline" , "${env.BUILD_URL} RELEASE Image ${appName}:${env.AppNewVersion} pushed to ECR !", "good"    
                            }
                        }
                    }catch(e){
                        slackNotifier.sendMsgPortal "ci_cd_bckend_pipeline" , "${env.BUILD_URL} Image ${appName}:${env.AppNewVersion} push to ECR FAILED !", "warning"    
                        sh "exit 1"
                    }
                }
            }
        }
        stage('Upload Artifact'){ // upload package to Nexus
            when{
                allOf {
                    anyOf{
                        branch 'release/*'
                    }
                    expression{env.SKIP_BUILD == "false" }
                }
            }
            steps{
                script{
                    nexus.uploadJarPom "${appName}" , "${env.AppNewVersion}" , "${appGroup}" , ''
                    nexus.uploadZipPackage "${appName}" , "${env.AppNewVersion}" , "${appName}-${env.AppNewVersion}.zip"
                }
            }
        }
        stage('Adjust Auto Bump Status'){ // to reflect latest build status
            when{
                allOf {
                    branch 'develop'
                    expression{env.SKIP_BUILD == "true" }
                }
            }    
            steps{
                script{
                    log.info "Setting the build job of AutomaticVersionBump with the same result than the previous build result of the develop branch!"
                    currentBuild.result = currentBuild.getPreviousBuild().result    
                }
            }
        }
    }
    post {
        always {
            script {
                cleanWs()
                chuckNorris()
            }
        }
        success {
            script {
                log.info 'Finished with SUCCESS...'
                updateGitlabCommitStatus state: 'success'
                slackNotifier.sendMsgPortal "ci_cd_bckend_pipeline" , "${env.BUILD_URL} finished with status: ${currentBuild.getCurrentResult()}!", "good"    
            }
        }
        unsuccessful {
            script {
                log.error 'Something failed...'
                email.sendEmailFailure 'joao.pedro@vodafone.com'
                updateGitlabCommitStatus state: 'failed'
                slackNotifier.sendMsgPortal "ci_cd_bckend_pipeline" , "${env.BUILD_URL} finished with status: ${currentBuild.getCurrentResult()}!", "danger"    
            }
        }
    }
}