<?php
declare(strict_types=1);
$NEW_LOCATION = 'https://amin-saml-sp.au.auth0.com/login/callback?connection=Mimics-KC-SP-unsigned-req';

if (isset($_POST["SAMLResponse"])) {
    $SAMLResponse = $_POST["SAMLResponse"];
    $RelayState = $_POST["RelayState"];
} else {
    die("params invalid");
}

// TODO: validate Signature, Destination, and Recipient condition before posting to new Destination
?>
<html lang="en">
<body onload="document.forms[0].submit()">
<form method="POST" action=<?= "$NEW_LOCATION" ?>>
    <input type="hidden" name="SAMLResponse" value="<?= $SAMLResponse ?>">
    <?php if (isset($RelayState)) { ?>
        <input type="hidden" name="RelayState" value="<?= $RelayState ?>">
    <?php } ?>
</form>
</body>
</html>