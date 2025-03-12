const https = require('node:https');
const { readFile, writeFile } = require('node:fs');

// First read the existing gitmojis-list.el file
readFile('./gitmojis-list.el', 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading existing file:', err);
    return;
  }

  // Get the latest gitmoji data
  https.get('https://raw.githubusercontent.com/carloscuesta/gitmoji/master/packages/gitmojis/src/gitmojis.json', (res) => {
    let rawData = '';

    res.on('data', (chunk) => {
      rawData += chunk;
    });

    res.on('end', () => {
      try {
        const { gitmojis } = JSON.parse(rawData);
        const gitmojisList = gitmojis.map(({ emoji, code, description }) =>
          `("${description}" "${code}" #x${emoji.codePointAt(0).toString(16).toUpperCase()})`
        );

        // Use regex to find and replace only the list part in defvar gitmojis-list
        const listPattern = /(defvar gitmojis-list\s*')'?\(([^]*?\))(\)\))/s;
        const newContent = data.replace(listPattern, (match, prefix, oldList, suffix) => {
          return `${prefix}(${gitmojisList.join('\n                        ')}${suffix}`;
        });

        // Write the updated content back to the file
        writeFile('./gitmojis-list.el', newContent, (err) => {
          if (err) {
            console.error('Error writing file:', err);
          } else {
            console.log('Successfully updated gitmojis-list.el');
          }
        });
      } catch (err) {
        console.error('Error processing data:', err);
      }
    });
  }).on('error', (e) => {
    console.error('Error fetching data:', e);
  });
});
