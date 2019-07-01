import ecr = require('@aws-cdk/aws-ecr');
import cdk = require('@aws-cdk/core');

export class AppMeshFluxFlaggerStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ECR
    new ecr.Repository(this, 'EcrRepository', {
      repositoryName: 'app-mesh-flux-flagger',
      removalPolicy: cdk.RemovalPolicy.DESTROY
    })
  }
}
