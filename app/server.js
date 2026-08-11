const express = require('express');
const app = express();

// Port env variable se aayega, agar nahi mila to 3000 default
const PORT = process.env.PORT || 3000;

app.use(express.static('public'));

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>cloudwithshalvi.online</title></head>
      <body style="font-family: Arial; text-align:center; margin-top: 80px;">
        <h1>🚀 Welcome to cloudwithshalvi.online</h1>
        <p>Deployed via AWS CodePipeline + CodeDeploy on EC2</p>
        <p>Running on port: ${PORT}</p>
      </body>
    </html>
  `);
});

// Health check endpoint - CodeDeploy ValidateService hook isse check karega
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
