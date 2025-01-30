## Packer

# Has to be run from folder: images-using-azure-image-builder\LenVolk\packer

## Validate Image

packer validate -var-file ./secret/secret_packer.json -var-file packer-var.json packer.json

## Inspect

packer inspect -var-file ./secret/secret_packer.json -var-file packer-var.json packer.json

## Build Image
# only run this
packer build -force -var-file ./secret/secret_packer.json -var-file packer-var.json packer.json
# 
packer build -debug -force -var-file ./secret/secret_packer.json -var-file packer-var.json packer.json

## Fix

packer fix -h -var-file packer_optimization.json


### If you need to pause and logging to the VM

    {
      "type": "breakpoint",
      "note": "Let's login to the system before starting the build"
    },
