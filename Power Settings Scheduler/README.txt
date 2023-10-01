### How to run the script:

You can run this script directly by calling it from PowerShell and providing the parameter like:

```powershell
.\SetPowerProfile.ps1 -powerProfile "High performance"
```

### Set up in Task Scheduler:

1. Open the Task Scheduler and create a new task.
2. In the "General" tab, give your task a name and description.
3. In the "Triggers" tab, set up the schedule on which you want the task to run.
4. In the "Actions" tab, choose "Start a program" as the action.
5. In the "Program/script" field, put `powershell.exe`.
6. In "Add arguments (optional)", put `-File "C:\Path\To\Your\Script\SetPowerProfile.ps1" -powerProfile "High performance"` (replace the path and powerProfile value as needed).
7. Complete the setup, and the task will run the script with the provided parameter at the scheduled times.

Make sure to replace `"C:\Path\To\Your\Script\SetPowerProfile.ps1"` with the actual path where you saved the script.