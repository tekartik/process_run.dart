# Manipulate environment

Binary utility that allow changing from the command line the environment (var, path, alias) used in Shell.

### Example
```
# Version
ds --version

# Run using the shell environment (alias, path and var=
ds run echo Hello World

# Set a var
ds env var set MY_VAR my_value

# Set an alias
ds env alias set ll ls -l

# Add a path (prepend only)
ds env path prepend dummy/relative/folder
```
