# Cry

Cry is a simple CLI tool for testing APIs, built entirely with Bash.  

## Powered by Curl  

This tool is essentially an abstraction over `curl`, allowing you to modularize HTTP requests into **commands**.  

## Installation  

> [!NOTE]  
> Cry is a **bpm package**, so you must have [bpm](https://github.com/Raffa064/bpm) installed to use it.  

To install Cry, run:  

```bash
bpm install cry
```

After done, will be able to run it with `bpm run cry`. To avoid calling bpm run every time, you can export it:

```bash
bpm export cry
```

It's done. Now you can use it anywhere simply by calling `cry <command>`.

## Usage  

To use Cry, you need to create a script file called `cry.sh` inside a directory. This file defines your **Cry commands** and determines the root of Cry's working directory—just like `git` and `npm` do.  

Each command in `cry.sh` starts with `begin <command-name>` and ends with `end`.  

```bash
# Example Cry command
begin command-name
  # Command configuration goes here...
end 
```

Within this block, you define everything related to the command. Let's start by specifying a URL and an HTTP method:  

```bash
begin create-user
  post http://localhost:8080/create-user 
end
```

> [!NOTE]  
> This command assumes a server is running on `localhost:8080` with an endpoint at `/create-user`.  

This sends a `POST` request, but without any data. Let’s add a JSON payload:  

```bash
begin create-user
  post http://localhost:8080/create-user 

  # Specify content type
  header Content-Type application/json

  # JSON payload
  body '{
    "name": "Example",
    "email": "example@email.com",
    "password": "password123"
  }'
end
```

Now, to execute the command, run:  

```bash
cry create-user
```

### Cry's Cache Directory  

> [!NOTE]  
> Each time you run `cry`, it generates a hidden `.cry` directory in the same folder as `cry.sh`.  
> This directory stores cached metadata, cookies, and temporary files.  
> You can delete it, but it will be recreated whenever `cry` runs.  

The output of a command depends on the server's response. It includes the full HTTP response and a status message. If everything works as expected, the response should return **200 OK**, indicating that the user was successfully created.  

## Handling Cookies  

If your API returns an **access token** via **cookies**, you can store it for future requests using the `use-cookies` function:  

```bash
begin create-user
  post http://localhost:8080/create-user
  use-cookies session-token
end
```

This will store all cookies returned by the server in `.cry/cookies/session-token`. If the file already exists, its contents will be sent with the request.  

## Required Fields  

Sometimes, you need different values for the same command. Instead of modifying the script manually, use `require` to define variables that Cry will prompt for at runtime:  

```bash
begin create-user
  require name email password
  post http://localhost:8080/create-user
  use-cookies %name # Unique cookie per user
  header Content-Type application/json 
  body '{
    "name": "%name",
    "email": "%email",
    "password": "%password"
  }'
end
```

Here, `%name`, `%email`, and `%password` are **placeholders**. When you run:  

```bash
cry create-user
```

Cry will prompt for values:  

```bash
Enter value for 'name': Example  
Enter value for 'email': example@email.com  
Enter value for 'password': example123  
```

> **Why `%var` instead of `$var`?**  
> These are not regular shell variables. Any shell variable used in `cry.sh` is treated as a **constant** because the script is only executed when `cry gen` runs, not every time a command is called.  

## Templates  

If you need to reuse a command with slight modifications, use the `use-template` function:  

```bash
begin create-admin
  use-template create-user # Copies everything from create-user
  
  # Override required fields
  name="Admin"
  email="admin@example.com"
  password="admin123"
end
```

> [!WARNING]  
> `use-template` **overwrites all settings defined before it**, so customizations should be placed **after** it.  

Now, you can run:  

```bash
cry create-admin
```

without needing to enter credentials every time.  

> [!NOTE]  
> These variables (`name`, `email`, `password`) **only exist within this command**.  
> They are not inherited by templates.  

## Miscellaneous  

- Use `-e` to print the `curl` command instead of executing it:  
  ```bash
  cry -e create-user
  ```
- Open `cry.sh` in an editor using:  
  ```bash
  cry edit
  ```
- List `.cry` directory contents:  
  ```bash
  cry list
  ```
- Force command regeneration:  
  ```bash
  cry gen
  ```
- Define a base URL for all commands using `host`:  
  ```bash
  host http://localhost:8080
  ```
