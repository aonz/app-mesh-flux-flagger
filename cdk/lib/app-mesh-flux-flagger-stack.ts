import cdk = require('@aws-cdk/core');
import ec2 = require('@aws-cdk/aws-ec2');
import ecr = require('@aws-cdk/aws-ecr');
import eks = require('@aws-cdk/aws-eks');
import iam = require('@aws-cdk/aws-iam');

export class AppMeshFluxFlaggerStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ECR
    new ecr.Repository(this, 'EcrRepository', {
      repositoryName: 'app-mesh-flux-flagger',
      removalPolicy: cdk.RemovalPolicy.DESTROY
    })

    // EKS
    const vpc = new ec2.Vpc(this, 'Vpc', { cidr: '12.0.0.0/24' });
    const cluster = new eks.Cluster(this, 'EksCluster', {
      clusterName: 'AppMeshFluxFlagger',
      vpc,
      vpcSubnets: [{ subnetType: ec2.SubnetType.PUBLIC }]
    });
    const autoScalingGroup = cluster.addCapacity('EksNodes', {
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE },
      instanceType: new ec2.InstanceType('t3.medium'),
      desiredCapacity: 1,
    });
    autoScalingGroup.connections.allowFrom(ec2.Peer.anyIpv4(), ec2.Port.allTraffic(), 'Allow from anyone on any port');
    autoScalingGroup.role.addManagedPolicy(iam.ManagedPolicy.fromAwsManagedPolicyName('AdministratorAccess'));
  }
}
