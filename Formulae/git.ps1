formula git {
    version "1.9.5-preview20150319"
    url "https://github.com/msysgit/msysgit/releases/download/Git-1.9.5-preview20150319/PortableGit-1.9.5-preview20150319.7z" -Hash "26261872847B18D171A197C8E4B3F4C0E60B4310C4B8EF1F4D9884950288AA7C"

    on install {
        bin "cmd\git.exe"
        bin "cmd\gitk.cmd"
        bin "cmd\start-ssh-agent.cmd"
    }
}
