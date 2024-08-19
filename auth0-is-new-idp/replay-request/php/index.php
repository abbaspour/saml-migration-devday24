<?php
// Route the request to the appropriate script
if (preg_match('/^\/realms\/master\/protocol\/saml$/', $_SERVER["REQUEST_URI"])) { # KeyCloak default URL
    require 'saml_replay.php';
} else {
    return false; // Serve the requested file as is
}
