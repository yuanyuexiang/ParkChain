const Hash = await import("npm:ipfs-only-hash@4.0.0");
const assetId = args[0];

const url = `https://park.matrix-net.tech/park/v1/parking-spot?query=id:${assetId}`;
const response = await Functions.makeHttpRequest({
  url: url,
  method: "GET",
  headers: {
    accept: "application/json",
  },
});

const result = response.data.data.list[0];
if (response.error) {
  throw Error("Error fetching balance");
}

// console.log(url);
// console.log(args);
// console.log(result);
const metadata = {
  name: "Park Lot Token",
  attributes: [
    { trait_type: "id", value: result.id },
    { trait_type: "address", value: result.address },
    { trait_type: "name", value: result.name },
    { trait_type: "status", value: result.status },
    { trait_type: "longitude", value: result.longitude },
    { trait_type: "latitude", value: result.latitude },
    { trait_type: "renter", value: result.renter },
    { trait_type: "rent_price", value: result.rent_price },
    { trait_type: "content", value: result.content },
    { trait_type: "remarks", value: result.remarks },
    { trait_type: "create_time", value: result.create_time },
    { trait_type: "update_time", value: result.update_time },
  ],
};

const metadataString = JSON.stringify(metadata);
const ipfsCid = await Hash.of(metadataString);
return Functions.encodeString(`ipfs://${ipfsCid}`);
