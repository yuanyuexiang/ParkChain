///this javascript code is to fetch the balance of the account,but fetch stock shares can be a better option

const userId = args[0];
const url = `https://park.matrix-net.tech/park/v1/user?query=id:${userId}`;
const response = await Functions.makeHttpRequest({
  url: url,
  method: "GET", // Optional
  // Other optional parameters
  headers: {
    accept: "application/json",
  },
});

const result = response.data;
if (response.error) {
  throw Error("Error fetching balance");
}
return Functions.encodeString("result");
