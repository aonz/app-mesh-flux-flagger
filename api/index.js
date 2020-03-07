const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

const { version } = require('./package.json');

app.get('/', (req, res) => res.json({ message: 'App Mesh x Flux x Flagger' }));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.get('/version', (req, res) => res.json({ version }));

app.listen(port, () => console.log(`Example app listening on port ${port}!`));