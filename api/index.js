const axios = require('axios');
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

const { version } = require('./package.json');

app.get('/', (req, res) => res.json({ message: 'App Mesh x Flux x Flagger' }));

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.get('/version', (req, res) => res.json({ version }));

app.get('/test', async (req, res) => {
    const { query } = req;
    const count = parseInt(query.count ? query.count : (process.env.COUNT || 100));
    const data = { count, versions: {}, percentages: {} };
    try {
        const promises = [];
        const url = 'http://backend.flagger/version';
        for (i = 0; i < count; i++) {
            promises.push(axios.get(url, { headers: { 'Cache-Control': 'no-cache' } }));
        }
        const results = await Promise.all(promises);
        results.forEach(result => {
            const version = result.data.version;
            if (!data.versions[version]) {
                data.versions[version] = 0;
            }
            data.versions[version]++;
        });
        for (let [key, value] of Object.entries(data.versions)) {
            data.percentages[key] = `${((value / count) * 100).toFixed(2)}%`;
        };
        console.log(data);
    } catch (error) {
        console.log(error.message);
    }
    res.json(data);
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`));