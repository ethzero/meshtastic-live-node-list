/*
    Here you will be able to configure lists of nodes that you wish to visually
    highlight including HAM Callsigns that will automatically link to QRZ.com

    To keep things simple, if you wish to match two personal nodes called:
    * m.ethzero.uk/#router
    * m.ethzero.uk/#mobile
    ... you only need use the string 'm.ethzero.uk' to match both. 
    
    It is possible to specify an ECMAScript Regular Expression for precise
    matching. I'd highly recommend https://regex101.com/ for this purpose.

    NB: Remember that the last -or- only entry in a list
        should *NOT* include a comma at the end!
*/

var nodeListPersonal = [
    'm.ethzero.uk'
];

var nodeListFrequentlyContactable = [
    'TechMinds',
    'M0DQW',
    'BigCW',
    'Terminus Base Station',
    'Whitchurch Router',
    'Meshtastic JTGW',
    'sk     '
];

var nodeListRarelyContactable = [
    'M0MEZ',
    'M0MBO',
    'M7SYN',
    'G0TAI',
    'M0UKF',
    'M6MCI',
    'Newton Longville 682c',
    'Yanovich',
    'Cranfield_Router G4JXZ',
    'Half Life',
    'Solar Node 2'
];

// Reasonably, but not perfectly, matches a *UK* HAM Callsign.
var nodeListHAMCallSign = [
    '(M3|M6|M7|M8|2E0|2E1|G1|G2|G3|G4|G5|G6|G7|G8|G0|M0|M1|M5|G\\d{1,2}|M\\d{1,2})[A-Z]{2,3}' 
];

var nodeListNewlyProvisioned = [
    'Meshtastic [0-9a-fA-F]{4}'
];

// UNK: 3662952560 
var nodeListUnknown = [
    'UNK: [0-9]{10}'
];


