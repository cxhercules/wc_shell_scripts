# wc_shell_scripts
The Wicked Cool Shell Scripts from Dave Taylor and more

# Notes
`sed -n {X}p <filename> # Will only print that line`

# Weeding out missing double quotes
```
./hilow: line 19: unexpected EOF while looking for matching `"'
./hilow: line 22: syntax error: unexpected end of file
```
# The error at least indicates that there is no matching ". 
```
grep '"' hilow |egrep -v '.*".*".*'
echo "... smaller!
```
