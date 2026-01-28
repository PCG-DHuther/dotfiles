---
applyTo: '**/*.ps1 , **/*.psm1'
description: "PowerShell-specific guidelines for code generation and review."
---

# Style Guidelines
- Capitalize keywords such as `if`, `else`, `foreach`, `while`, `switch`, `try`, `catch`, and `finally`. This improves readability and maintains consistency with common PowerShell conventions.

- Unless I request otherwise, specify switch parameters at the front of the line to improve readability. When possible, specify parameters in an order that most closely mirrors natural language describing what the cmdlet is doing. Example:
  ```powershell

  # Preferred
  Get-ChildItem -Force -File -Filter "*.md" -Recurse -Depth 3 -Path "C:\Temp"

  # Less Preferred; approximately the order suggested by parameter position/Intellisense
  Get-ChildItem -Path "C:\Temp" -Filter "*.md" -Recurse -Depth 3 -File -Force
  ```
- When a conditional statement or a pipeline includes a scriptblock that is very short, such as a single command or expression, it is preferred to place the scriptblock on the same line as the conditional or pipeline operator. Example:
  ```powershell
  # Preferred for short scriptblocks
  if ($user.IsActive) { Send-WelcomeEmail -User $user }

  # Less Preferred; more verbose for short scriptblocks
  if ($user.IsActive) {
      Send-WelcomeEmail -User $user
  }
  ```
- Continuing from above, if the conditional has multiple branches, prefer placing the branch with the shorter scriptblock first so it can continue on the same line, only opening to a new indentation level for larger ones. If necessary, the conditional can be inverted to accomodate this unless it alters the logic. Example:
  ```powershell
  # Preferred for mixed-length branches
  If (-not $user.IsActive) { Write-Host "User is not active." } Else {
      Send-WelcomeEmail -User $user
      Enable-ADUser -Identity $user.SamAccountName
      New-Mailbox -User $user.UserName
  }

  # Avoid:
  If ($user.IsActive) {
      Send-WelcomeEmail -User $user
      Enable-ADUser -Identity $user.SamAccountName
      New-Mailbox -User $user.UserName
  } Else {
      Write-Host "User is not active. No email sent."
  }
  ```

# Coding Guidelines
- Use four spaces for indentation to ensure consistent formatting across different editors and environments.
- Use splatting liberally for cmdlets with multiple parameters to enhance readability and maintainability. Strongly type the hashtable with "Hashtable" capitalized. Prefer names for the hashtable that describe what is done using those parameters, for example, acting as direct or indirect object to the verb of the cmdlet. Example:
  ```powershell
  # Preferred
  $logFilesFromTemp = @{
      Path    = "C:\Temp"
      Filter  = "*.log"
      Recurse = $true
      Force   = $true
  }
  Get-ChildItem @logFilesFromTemp

  # Less Preferred; all parameters inline
  Get-ChildItem -Path "C:\Temp" -Filter "*.log" -Recurse -Force
  ```
- Never use backticks (`) for line continuation. If a command contains pipelines, break the line at the pipeline character (|) and continue on the next line. If pipelines are absent and the length comes from number and length of parameters/values, use splatting with a hashtable as mentioned above. Example of pipes as line breaks:

  ```powershell
  Get-ChildItem -Path "C:\Temp" -Recurse |
      Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 10
  ```
- When possible, strongly type variables, parameters, and return types to improve code clarity and catch potential errors early. Example:
  ```powershell
  # Preferred
  function Get-ActiveUsers {
      [CmdletBinding()]
      [OutputType([System.Collections.Generic.List[User]])]
      Param(
          [Parameter(Mandatory)]
          [string]$Role
      )

      [Hashtable]$activeUsers = @{}
      # Function logic here
  }

  # Avoid unnecessarily untyped parameters, variables, return type
  function Get-ActiveUsers {
      Param(
          $Role
      )

      $activeUsers = @{}
      # Function logic here
  }
  ```
- Prefer using the pipeline over intermediate variables to hold data whenever this does not reduce clarity. This reduces the number of lines of code and can improve performance by avoiding unnecessary variable assignments. Example:
  ```powershell
  # Preferred
  Get-Process | Where-Object { $_.CPU -gt 100 } | Sort-Object CPU -Descending | Select-Object -First 5

  # Less Preferred; uses intermediate variables
  $processes = Get-Process
  $highCpuProcesses = $processes | Where-Object { $_.CPU -gt 100 }
  $sortedProcesses = $highCpuProcesses | Sort-Object CPU -Descending
  $topProcesses = $sortedProcesses | Select-Object -First 5
  ```
- When creating Foreach loops, name the temporary variable using a single letter (for example, the first letter of the collection we're iterating through). This reduces code size, improves readability, and clearly differentiates the temporary loop-scoped variable from the collection variable. Example:
  ```powershell
  # Preferred
  $users = Get-UserList
  foreach ($u in $users) { Send-Notification -User $u}

  # Less Preferred; longer temporary variable name
  $users = Get-UserList
  foreach ($user in $users) { Send-Notification -User $user}
  ```
- Avoid using plural names for variables and parameters. Prefer singular names for collections (e.g., *List, *Collection, *Array) when the variable would otherwise be plural, ensuring compliance with PowerShell's recommended style conventions.
  ```powershell
  # Preferred
  $userList = Get-User -All

  # Less Preferred; plural variable name
  $users = Get-User - All
    ```