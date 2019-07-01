#!/usr/bin/env node

import cdk = require('@aws-cdk/core');
import { AppMeshFluxFlaggerStack } from '../lib/app-mesh-flux-flagger-stack';

const app = new cdk.App();
new AppMeshFluxFlaggerStack(app, 'AppMeshFluxFlaggerStack');
app.synth();
