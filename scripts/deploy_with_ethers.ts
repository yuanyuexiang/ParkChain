import { deploy } from './ethers-lib'

(async () => {
  try {
    const result = await deploy('ParkingLot', [])
    console.log(`address: ${result.address}`)
  } catch (e) {
    console.log(e.message)
  }
})()