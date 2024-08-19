<?php

function isPostRequest() {
    return $_SERVER['REQUEST_METHOD'] === 'POST';
}

function getParameter($name) {
    if (isset($_POST[$name])) {
        return $_POST[$name];
    } elseif (isset($_GET[$name])) {
        return $_GET[$name];
    }
    return null;
}

$samlRequest = getParameter('SAMLRequest');
$relayState = getParameter('RelayState');
$destinationUrl = 'https://amin-saml-idp.au.auth0.com/samlp/lsWN96muQQk5f3gaoAR9Ix8JTARsuqkC'; // Replace with the new SAML Sign In URL

if (isPostRequest()) {
    // Auto form post
    echo "<form id='samlForm' action='$destinationUrl' method='POST'>";
    echo "<input type='hidden' name='SAMLRequest' value='" . htmlspecialchars($samlRequest, ENT_QUOTES, 'UTF-8') . "' />";
    echo "<input type='hidden' name='RelayState' value='" . htmlspecialchars($relayState, ENT_QUOTES, 'UTF-8') . "' />";
    echo "</form>";
    echo "<script type='text/javascript'>document.getElementById('samlForm').submit();</script>";
} else {
    // GET request - redirect with 302
    $queryParams = http_build_query([
        'SAMLRequest' => $samlRequest,
        'RelayState' => $relayState
    ]);
    header("Location: $destinationUrl?$queryParams", true, 302);
    exit();
}

