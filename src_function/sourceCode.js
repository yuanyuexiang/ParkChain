const Hash = await import("npm:ipfs-only-hash@4.0.0");
const userId = args[0];
const url = `https://park.matrix-net.tech/park/v1/user?query=id:${userId}`;
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
    { trait_type: "email", value: result.email },
    { trait_type: "number", value: result.number },
    { trait_type: "content", value: result.content },
    { trait_type: "status", value: result.status },
    { trait_type: "remarks", value: result.remarks },
    { trait_type: "create_time", value: result.create_time },
    { trait_type: "update_time", value: result.update_time },
  ],
};

const metadataString = JSON.stringify(metadata);
const ipfsCid = await Hash.of(metadataString);
return Functions.encodeString(`ipfs://${ipfsCid}`);
