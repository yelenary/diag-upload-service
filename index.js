const fileUpload = require('express-fileupload');
const express = require('express')
const app = express();
const port = 8000;

const diagDir = 'diags'
app.use(fileUpload());
app.use(express.static(diagDir))

app.post('/upload', (req, res) => {
    if (!req.files || Object.keys(req.files).length === 0) {
        return res.status(400).send('No files uploaded.');
    }
    let diag = req.files.diag;
    if (!diag.name.indexOf(".tgz") || (diag.name.length - diag.name.indexOf(".tgz")-1)!=3 ){
        console.log(`Not compatible diag file format provided: ${diag.name}`)
        return res.status(400).send('Not compatible diag file format provided. *.tgz file required.');
      }
    diag.mv(`${diagDir}/${diag.name}`, function (err) {
        if (err) {
            return res.status(500).send(err);
        }
    });
    res.send(`File ${diag.name} uploaded`);
    console.log(`File uploaded: ${diag.name}`)
})

app.get('/download/:id', (req, res) => {
    res.sendFile(req.params.id, {root: diagDir})
})

app.get('/', (req, res) => {
    res.send('Diag Service')
});

app.listen(port, () => {
    console.log(`App is listening on port ${port}!`)
});
