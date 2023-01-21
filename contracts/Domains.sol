// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {StringUtils} from "./libraries/StringUtils.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "hardhat/console.sol";

contract Domains is ERC721URIStorage {
    address payable public owner;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><defs><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path style="stroke:none;fill-rule:nonzero;fill:#4e2d4e;fill-opacity:1" d="M23.828 3.457c-1.172.45-2.129 1.856-2.148 3.145 0 .683.566 1.953 1.054 2.363.176.156.313.332.313.43 0 .136-8.281 13.964-8.496 14.199-.02.039-1.836-.996-4.024-2.266l-3.964-2.324.039-.86c.078-1.21-.606-2.48-1.622-3.046-2.695-1.524-5.898 1.27-4.707 4.101.372.899 1.543 1.875 2.442 2.012l.762.117.683 2.48c.371 1.348 1.367 4.942 2.207 7.989l1.524 5.508h34.218l1.524-5.508c.84-3.047 1.836-6.64 2.207-7.988l.683-2.48.762-.118c.899-.137 2.07-1.113 2.442-2.012.644-1.523-.02-3.32-1.485-4.101-1.054-.547-1.972-.567-3.047-.04-1.133.547-1.718 1.524-1.777 2.91l-.02 1.055-3.945 2.325c-2.187 1.27-3.984 2.285-4.004 2.246-.176-.196-8.496-14.063-8.496-14.16 0-.059.254-.391.586-.762 1.797-2.07.234-5.39-2.539-5.332-.488 0-1.016.058-1.172.117ZM7.48 41.602c-1.699 1.015-1.62 3.867.118 4.785.507.254 2.597.293 17.402.293 18.555 0 17.578.058 18.36-1.23.507-.821.507-2.188 0-3.009-.782-1.289.214-1.23-18.4-1.23-16.366 0-16.874.02-17.48.39Zm0 0"/><defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#f8ecce"/><stop offset="1" stop-color="#fff" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#4e2d4e" filter="url(#b)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = "</text></svg>";
    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(string => uint256) public unique;
    mapping(uint256 => string) public names;

    constructor(string memory _tld) payable ERC721("King Name Service", "KNS") {
        owner = payable(msg.sender);
        tld = _tld;

        unique["pirate"] = 2;
        unique["burger"] = 2;
        unique["the"] = 2;
        unique["zoro"] = 1;
        unique["luffy"] = 1;
        unique["joyboy"] = 1;
        unique["haki"] = 1;
        unique["ussop"] = 1;
        unique["nami"] = 1;
        unique["chopper"] = 1;
        unique["jimbei"] = 1;
        unique["brook"] = 1;
        unique["franky"] = 1;
        unique["sanji"] = 1;

        console.log("%s name service deployed", _tld);
    }

    error Unauthorized();
    error AlreadyRegistered();
    error InvalidName(string name);

    function valid(string calldata name) public pure returns (bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
    }

    function price(string calldata name) public view returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0);
        if (unique[name] == 2) {
            return 10**19;
        } else if (unique[name] == 1) {
            return 10**18;
        } else if (len == 3) {
            return 5 * 10**17; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
            return 3 * 10**17; // To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
            return 1 * 10**17;
        }
    }

    function register(string calldata name) public payable {
        if (domains[name] != address(0)) revert AlreadyRegistered();
        if (!valid(name)) revert InvalidName(name);

        require(domains[name] == address(0));
        uint256 _price = price(name);
        require(msg.value >= _price, "Not enough Matic paid");
        string memory _name = string(abi.encodePacked(name, ".", tld));
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );

        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A domain on the King name service", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                strLen,
                '"}'
            )
        );
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        console.log("\n--------------------------------------------------------");
        console.log("Final tokenURI", finalTokenUri);
        console.log("--------------------------------------------------------\n");

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;
        names[newRecordId] = name;
        _tokenIds.increment();

        console.log("%s has registered a domain!", msg.sender);
    }

    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name)
        public
        view
        returns (string memory)
    {
        return records[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Matic");
    }

    function getAllNames() public view returns (string[] memory) {
        console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }
}
