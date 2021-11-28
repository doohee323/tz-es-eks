# tz-es-eks
TZ's main eks cluster with terraform

* forked from https://github.com/terraform-aws-modules/terraform-aws-eks

## prep)
```
    1) copy aws configuration files
        resources/project   # change your project name, it'll be a eks cluster name.
        resources/config    # default profile required
        resources/credentials
    
        ex)
        vi resources/project
        aws_account_id=xxxxxxx
        project=es-eks-a
        domain=ejntest.com
        github_id=doohee.hong
        admin_password=xxxxx

        vi resources/config
        [default]
        region = us-west-1
        output = json
        
        vi resources/credentials
        [default]
        aws_access_key_id = xxx
        aws_secret_access_key = xxx

```

## change variables
``` 
    terraform-aws-eks/workspace/base/locals.tf
        cluster_name                  = "es-eks-a"
        region                        = "ap-northeast-2"
        environment                   =  "dev"
        VCP_BCLASS = "10.30"
    
    terraform-aws-eks/local.tf
        tags                          = [{key: "project", value: "es-eks-a", propagate_at_launch: true}]                          # A list of map defining extra tags to be applied to the worker group autoscaling group.
        iam_instance_profile_name     = "es-eks-a-ap-northeast-2-role"                          # A custom IAM instance profile name. Used when manage_worker_iam_resources is set to false. Incompatible with iam_role_id.
```

## run)
```

    vagrant up
    vagrant ssh

    kubectl get nodes

    * see your cluster info.
    vi /vagrant/info

```

## remove)
``` 
    * before destroying, run eks_remove_all.sh first!
    vagrant ssh
    cd /vagrant/scripts
    sudo bash eks_remove_all.sh
    exit

    vagrant destroy -f
```

## Ref.
``` 
    * After running it, these files are changed, but don't commit them.
    terraform-aws-eks/local.tf
    terraform-aws-eks/workspace/base/locals.tf
```

## https://weaveworks-gitops.awsworkshop.io/
## https://tf-eks-workshop.workshop.aws/000_workshop_introduction.html
## https://itnext.io/a-kubefed-tutorial-to-synchronise-k8s-clusters-86108194ed79
## https://betterprogramming.pub/build-a-federation-of-multiple-kubernetes-clusters-with-kubefed-v2-8d2f7d9e198a
## https://www.youtube.com/watch?v=PSwLdpH0vak


