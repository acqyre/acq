# acqyre
Tool to fetch apps on Windows.

## Getting started

0. `Set-ExecutionPolicy RemoteSigned` unless you've alrady done that
1. Run the following from a PowerShell window:

```powershell
&([scriptblock]::Create((curl https://raw.githubusercontent.com/acqyre/acqyre/master/Boot.ps1 | select -exp Content)))
```

## Using it

`acq install thing` Installs `thing`

`acq subscribe owner/repo` Clones `https://github.com/owner/acqyre-repo` into `C:\Library\Collections` so you can access formulae defined there

Make formula by creating a repo of PowerShell scripts using the Formula API. See https://github.com/anurse/acqyre-personal for examples.

## How it works

1. `acq install foo` searches `C:\Library\Collections` for `foo.ps1`
2. `foo.ps1` is executed and the result is a Formula object defining what to do
3. We download any packages referenced by `url` statements in the Formula and unpack them. Acq knows how to unpack `.zip`, `.7z` and `.msi` files. Anything we don't understand (like `.exe`) is just left unexecuted
4. We run the commands from the `on install` section.
  1. `bin foo.exe` places `foo.exe` from the unpacked package on the path by creating a `foo.cmd` in `C:\Library\Bin`


## Known Issues
A LOT. This isn't even beta, not even CTP or Alpha or Preview or SuperPreview or Private Closed Special Access Kickstarter Backer Beta. This is live development.
