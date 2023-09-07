# SpiderTrigger - Automated Deployment Tool

SpiderTrigger is a powerful tool designed to automate the process of deploying your applications on your own server, similar to platforms like Railway, Render, Vercel, Netlify, etc.

> [!IMPORTANT]\
> SpiderTrigger currently supports Node.js applications and is compatible with Linux platforms. However, future updates may introduce support for additional programming languages, frameworks, and platforms.

## When and Why You Need SpiderTrigger

SpiderTrigger is essential when you want to streamline the deployment process of your applications on your own server. It eliminates the manual steps involved in pulling your project from GitHub, building a Docker container, and running the container. With SpiderTrigger, you can save time and effort by automating these tasks, allowing you to focus on developing your application.

## Workflow Behind the Scenes

The workflow of SpiderTrigger is as follows:

1. **User pushes changes to GitHub:**
   Whenever you make changes to your codebase and push them to your GitHub repository, SpiderTrigger springs into action.

2. **GitHub sends a request to the local webhook server:**
   SpiderTrigger integrates seamlessly with GitHub's webhook functionality. Once you push changes, GitHub sends a request to your locally hosted webhook server.

3. **The webhook server triggers a script:**
   Upon receiving the webhook request, SpiderTrigger's script is automatically triggered. This script acts as the bridge between GitHub and your deployment process.

4. **Automatic creation or update of Docker container:**
   The script, powered by SpiderTrigger, initiates the creation of a new Docker container or updates the existing one. It pulls the latest changes from your GitHub repository, builds the Docker image, and runs the container with the updated code.

# Set Up SpiderTrigger on Your Own Server
## Prerequisites

Before deploying SpiderTrigger on your own server, make sure you have the following prerequisites installed:

- Go version 1.21.0 or later
- Docker

### Installing Go

To install Go, follow these steps:

1. Download the latest version of Go from the official website. For example, you can download Go 1.21.1 from [this link](https://go.dev/dl/go1.21.1.linux-amd64.tar.gz).

2. Remove any previous Go installation by deleting the `/usr/local/go` folder (if it exists).

3. Extract the downloaded archive into `/usr/local`, creating a fresh Go tree. Run the following command (you may need to run it as root or through sudo):
   ```bash
   rm -rf /usr/local/go && tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz
   ```

4. Add `/usr/local/go/bin` to the `PATH` environment variable. You can do this by adding the following line to your `$HOME/.profile` or `/etc/profile` (for a system-wide installation):
   ```bash
   export PATH=$PATH:/usr/local/go/bin
   ```

5. Verify that you've installed Go by opening a command prompt and typing the following command:
   ```bash
   go version
   ```
   Confirm that the command prints the installed version of Go.

For more information, please refer to the [official Go installation documentation](https://go.dev/doc/install).

### Installing Docker

To install Docker, follow these steps:

1. Install Docker using the package manager for your operating system. For example, on Ubuntu, you can use the following command:
   ```bash
   sudo apt install docker.io
   ```

2. Fix the permission error by performing the following steps:
   1. Create the `docker` group on the system:
      ```bash
      sudo groupadd -f docker
      ```
   2. Add the active user to the `docker` group:
      ```bash
      sudo usermod -aG docker $USER
      ```
   3. Apply the group changes to the current terminal session:
      ```bash
      newgrp docker
      ```
   4. Check if the `docker` group is in the list of user groups:
      ```bash
      groups
      ```

For more information, please refer to this [Installing Portainer with Docker and Configuring MTU.md](https://gist.github.com/OnCloud125252/2346b1a03ce9d7fd378bfa26b083799f).

## Deploying SpiderTrigger

There are two methods available for deploying SpiderTrigger on your own server: [downloading the pre-built release](#Method-1-Downloading-the-Release) or [building it from source](#Method-2-Building-from-Source).

### Method 1: Downloading the Release

1. **Download the latest release:**
   Visit the [releases page](https://github.com/OnCloud125252/SpiderTrigger/releases/latest) and download the latest release package for your operating system.

2. **Extract the package:**
   Extract the downloaded package to a directory of your choice on your server.  
   
   You can use the following command to extract the package into the home directory:
   ```bash
   unzip SpiderTrigger.zip -d ~
   ```

3. **Configure SpiderTrigger:**
   Open the configuration file (`config.yaml`) included in the extracted package and customize the settings according to your requirements.  
   
   The configuration file should have the following structure:
   ```yaml
   port: 8000
   path: /auto-deploy
   ```

You may now navigate to the [Finishing](#finishing) part to complete the deployment.

### Method 2: Building from Source

1. **Clone the SpiderTrigger repository:**
   Clone the SpiderTrigger repository from GitHub using the following command:
   ```bash
   git clone https://github.com/OnCloud125252/SpiderTrigger.git
   ```

2. **Navigate to the project directory:**
   Change into the SpiderTrigger directory:
   ```bash
   cd SpiderTrigger
   ```

3. **Install the required dependencies:**
   SpiderTrigger has a few dependencies that need to be installed before building.  
   Install the dependencies by running the following command:
   ```bash
   go mod download
   ```

4. **Configure SpiderTrigger:**
   Open the configuration file (`config.yaml`) and customize the settings according to your requirements.  
   The configuration file should have the following structure:
   ```yaml
   port: 8000
   path: /auto-deploy
   ```

5. **Build SpiderTrigger:**
   Build the SpiderTrigger executable by running the build script:
   ```bash
   chmod +x ./go_build.sh
   ./go_build.sh
   ```
   To build with a specific configuration file, use the following command:
   ```bash
   ./go_build.sh config.yaml
   ```
   It is recommended to use the build script because it can handle the dependencies correctly. If everything goes right, you will see a success message like below.  
   ![image](https://user-images.githubusercontent.com/75195127/266393614-7858a1ea-1ada-4768-8cda-7407975dd6c7.png)

You may now navigate to the [Finishing](#finishing) part to complete the deployment.

## Finishing

1. **Set up a webhook in GitHub:**
   1. Navigate to your GitHub repository's page.
   2. Click on the "Settings" tab.
   3. In the left sidebar, click on "Webhooks".
   4. Click on the "Add webhook" button.
   5. In the "Payload URL" field, enter the URL where SpiderTrigger is running, followed by the port and path you configured in the `config.yaml` file (e.g., `http://your-server-ip:8000/auto-deploy`).
   6. Select the events that should trigger the webhook. For automatic deployments, you can choose the "Push" event.
   7. Leave the other settings as their default values.
   8. Click on the "Add webhook" button to save the webhook configuration.

2. **Start SpiderTrigger:**
   If you're building SpiderTrigger from source, you need to navigate to the `_production` directory first.
   Run the executable file to start listening for webhook requests. It is recommended to use the `run_in_background.sh` script to run SpiderTrigger in the background.  
   
   To start SpiderTrigger in the background, use the following command:
   ```bash
   ./run_in_background.sh
   ```
   
   To stop SpiderTrigger, you have two options:
   - Use the `kill_run_in_background.sh` script by running the following command:
     ```bash
     ./kill_run_in_background.sh
     ```
   - Manually stop SpiderTrigger by killing the process using the stored PID. You can find the PID in the `nohup_pid` file.

Congratulations! You have successfully deployed SpiderTrigger on your own server. SpiderTrigger will now listen for webhook requests and automatically perform the deployment process whenever changes are pushed to your configured path.

> [!INFORMATION]\
> - SpiderTrigger only exposes one port inside the Docker container (default 9000) to a random port on the host. You can check which port on the host is mapped to the container using the `docker ps` command.
> - SpiderTrigger automatically injects an environment variable to the Docker container: `PORT=9000`. If your application needs to use a port, you can directly use the `PORT` environment variable.
> - Once you have the webhook link, you can use the same webhook for many projects. SpiderTrigger will handle them separately on different containers.
