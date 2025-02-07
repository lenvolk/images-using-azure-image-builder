## Packer

# Has to be run from folder: images-using-azure-image-builder\LenVolk\packer

## Validate Image
.\packer.exe init packer-config.pkr.hcl

.\packer.exe validate -var-file ./secret/secret_packer.json -var-file packerchoco-var.json packerchoco.json

## Inspect

.\packer.exe inspect ./secret/secret_packer.json -var-file packerchoco-var.json packerchoco.json

## Build Image
# only run this
.\packer.exe build -var-file ./secret/secret_packer.json -var-file packerchoco-var.json packerchoco.json

# 
.\packer.exe build -debug -force ./secret/secret_packer.json -var-file packerchoco-var.json packerchoco.json

## Fix

.\packer.exe fix -h -var-file packer_optimization.json


### If you need to pause and logging to the VM

    {
      "type": "breakpoint",
      "note": "Let's login to the system before starting the build"
    },
