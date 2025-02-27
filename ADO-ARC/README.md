# Azure Arc Manager Pipeline Diagram

```mermaid
flowchart TD
    %% Style definitions
    classDef stage fill:#2563eb,color:white,stroke:#1d4ed8,stroke-width:2px
    classDef job fill:#4f46e5,color:white,stroke:#4338ca,stroke-width:1px
    classDef task fill:#6366f1,color:white,stroke:#4338ca,stroke-width:1px
    classDef param fill:#818cf8,color:white,stroke:#4f46e5,stroke-width:1px

    %% Parameters
    subgraph Parameters
        ARCresourceGroup["ARCresourceGroup<br>Default: ARC"]
        OSType["OSType<br>Default: Windows"]
        ArcAgentVer["ArcAgentVer<br>Default: 1.48.02881.1941"]
    end
    
    %% Pipeline Stages
    subgraph Pipeline
        %% Stage 1
        stage1[removeARCDefender]
        subgraph jobs1[Jobs]
            job1[Remove_Extension]
            subgraph tasks1[Tasks]
                task1["AzurePowerShell<br>removeArcWinDefender.ps1"]
            end
        end
        
        %% Stage 2
        stage2[ArcChromeInstall]
        subgraph jobs2[Jobs]
            job2[InstallChrome]
            subgraph tasks2[Tasks]
                task2["AzurePowerShell<br>ArcChromeInstall.ps1"]
            end
        end
        
        %% Stage 3
        stage3[ArcAgentUpdate]
        subgraph jobs3[Jobs]
            job3[UpdateingAgent]
            subgraph tasks3[Tasks]
                task3["AzurePowerShell<br>ArcAgentUpdate.ps1"]
            end
        end
        
        %% Stage 4
        stage4[ARCNanoLinuxInstall]
        subgraph jobs4[Jobs]
            job4[ARCNanoLinuxInstall]
            subgraph tasks4[Tasks]
                task4["AzurePowerShell<br>NanoLinux.ps1"]
            end
        end
        
        %% Stage 5
        stage5[CleanupArcRunCommands]
        subgraph jobs5[Jobs]
            job5[Cleanup]
            subgraph tasks5[Tasks]
                task5["AzurePowerShell<br>CleanupArcRunCommands.ps1"]
            end
        end
    end
    
    %% Flow connections
    stage1 --> stage2
    stage2 --> stage3
    stage3 --> stage4
    stage4 --> stage5
    
    job1 --> task1
    job2 --> task2
    job3 --> task3
    job4 --> task4
    job5 --> task5
    
    ARCresourceGroup --> task1 & task2 & task3 & task4 & task5
    OSType --> task1 & task2 & task3 & task4
    ArcAgentVer --> task3 & task4
    
    %% Apply styles
    class stage1,stage2,stage3,stage4,stage5 stage
    class job1,job2,job3,job4,job5 job
    class task1,task2,task3,task4,task5 task
    class ARCresourceGroup,OSType,ArcAgentVer param