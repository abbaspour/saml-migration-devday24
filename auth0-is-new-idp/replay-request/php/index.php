<?php

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Route the request to the appropriate script
if (preg_match('/^\/realms\/master\/protocol\/saml$/', $path)) { # KeyCloak default URL
    require 'request-replay.php';
} elseif (preg_match('/^\/realms\/master\/broker\//', $path)) {
    require 'response-replay.php';
} else {
    return false; // Serve the requested file as is
}
