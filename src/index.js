const express = require( "express" );
const app = express();

let port = 8080;
if (process.env.ENV === 'prod') { 
    port = process.env.PORT 
}

// define a route handler for the default home page
app.get( "/", ( req, res ) => {
    res.send( `${port}# Hello! The weather in San Diego is sunny!` );
} );

// start the Express server
app.listen( port, () => {
    console.log( `server started at http://localhost:${ port }` );
} );