const axios = require('axios');
const sleep = require('sleep');

async function test() {
    try {
        const url = process.env.COUNT ? `${process.env.URL}?count=${process.env.COUNT}` : process.env.URL;
        const { data } = await axios.get(url, { headers: { 'Cache-Control': 'no-cache' } });
        const { count, versions, percentages } = data;
        console.clear();
        console.log(`Time:  ${new Date().toLocaleTimeString('en-US', { hour12: false })}`);
        console.log(`Count: ${count}`);
        console.log(`Versions:`);
        for (let [key, value] of Object.entries(versions).sort((a, b) => a[0].localeCompare(b[0]))) {
            console.log(`    ${key}: ${value}, ${percentages[key]}`);
        };
    } catch (error) {
        console.log(error.message);
    }
}

async function loop() {
    while (true) {
        await test();
        await sleep.sleep(process.env.SLEEP || 3);
    }
}

loop();