# infra

## **Usage**

You can interact with your Docker Compose stacks using `make` commands. Many commands support the `ARGS` variable to pass additional arguments directly to the `docker compose` command.

### **Global Stack Management**

These commands apply to **all** discovered Docker Compose stacks.

| Command | Description | Example Usage |
| ----- | ----- | ----- |
| `make all-envs` | Prepares the `.env` file for all discovered stacks. This merges the common environment variables with any stack-specific ones into a `.env` file within each stack's directory, which Docker Compose then uses. | `make all-envs` |
| `make up` or `make up-all` | Brings up all Docker Compose stacks. **Highly recommended to use with `ARGS="-d"` for detached mode.** | `make up ARGS="-d"` |
| `make down` or `make down-all` | Takes down (stops and removes containers, networks, and default volumes) all Docker Compose stacks. | `make down` |
| `make clean` | Removes all generated `.env` files from all stack directories. This helps ensure a fresh environment on subsequent runs. | `make clean` |

Export to Sheets

### **Stack-Specific Commands**

For each stack discovered in your `$(STACKS_ROOT)` directory (e.g., if you have `stacks/my_stack`), the Makefile generates a set of commands. Replace `<stack_name>` with the actual name of your stack.

| Command | Description | Example Usage (for `my_stack`) |
| ----- | ----- | ----- |
| `make <stack_name>-env` | Prepares the `.env` file specifically for `<stack_name>`. This is implicitly run by other stack-specific commands. | `make my_stack-env` |
| `make <stack_name>-up` | Brings up the Docker Compose services for `<stack_name>`. Can be used with `ARGS` for options like detached mode (`-d`). | `make my_stack-up ARGS="-d"` |
| `make <stack_name>-down` | Takes down the Docker Compose services for `<stack_name>`. | `make my_stack-down` |
| `make <stack_name>-logs` | Displays the logs for the Docker Compose services in `<stack_name>`. Use `ARGS="-f"` to follow the logs in real-time. | `make my_stack-logs ARGS="-f"` |
| `make <stack_name>-ps` | Lists the running services and their status for `<stack_name>`. | `make my_stack-ps` |
| `make <stack_name>-build` | Builds or re-builds the Docker images defined in `compose.yaml` for `<stack_name>`. | `make my_stack-build` |
| `make <stack_name>-pull` | Pulls the Docker images for services in `<stack_name>`. | `make my_stack-pull` |
| `make <stack_name>-restart` | Restarts the Docker Compose services for `<stack_name>`. | `make my_stack-restart` |
| `make <stack_name>-stop` | Stops the running Docker Compose services for `<stack_name>` without removing their containers. | `make my_stack-stop` |
| `make <stack_name>-start` | Starts the stopped Docker Compose services for `<stack_name>`. | `make my_stack-start` |
| `make <stack_name>-config` | Validates and displays the effective Docker Compose configuration for `<stack_name>`. | `make my_stack-config` |
| `make <stack_name>-exec ARGS="<service> <command>"` | Executes a command inside a running service container within `<stack_name>`. Replace `<service>` and `<command>`. | `make my_stack-exec ARGS="web bash"`\&lt;br\>`make my_stack-exec ARGS="db psql -U user"` |

Export to Sheets

### **Passing Additional Arguments to Docker Compose**

Many commands accept an `ARGS` variable to pass extra parameters directly to the underlying `docker compose` command.

| Variable | Description | Example |
| ----- | ----- | ----- |
| `ARGS` | Pass any additional arguments to the Docker Compose command. | `make my_stack-up ARGS="-d --force-recreate"` |
|  | Used for `up`, `down`, `logs`, `build`, `exec`, etc. | `make my_stack-logs ARGS="--tail 50 web"` |
