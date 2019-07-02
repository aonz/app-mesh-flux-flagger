#!/usr/bin/env node

import cdk = require('@aws-cdk/core');
import { AppMeshFluxFlaggerStack } from '../lib/app-mesh-flux-flagger-stack';

const region = process.env.REGION || 'ap-southeast-1';

const app = new cdk.App();
new AppMeshFluxFlaggerStack(app, 'AppMeshFluxFlaggerStack', { env: { region } });
app.synth();
