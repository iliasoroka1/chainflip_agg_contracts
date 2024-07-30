import { MongoClient, Db } from 'mongodb';

const uri: string = process.env.MONGODB_URI as string; // Your MongoDB connection string

// Check if URI is provided
if (!uri) {
  throw new Error('Please define the MONGODB_URI environmental variable');
}

const client: MongoClient = new MongoClient(uri);


export async function connectToDatabase(): Promise<Db> {
  try {
    await client.connect();
    const dbConnection = client.db(); // You can specify your database name here
    return dbConnection;
  } catch (error) {
    console.error('Failed to connect to the database:', error);
    throw new Error('Failed to connect to the database');
  }
}

export async function getDataFromCollection(collectionName: string): Promise<any> {
  try {
    const db = await connectToDatabase();
    const collection = db.collection(collectionName);
    const data = await collection.find({}).toArray();
    await client.close();
    return data;
  } catch (error) {
    console.error('Failed to get data from collection:', error);
    throw new Error('Failed to get data from collection');
  }
}

export async function closeDatabaseConnection(): Promise<void> {
  try {
      await client.close();
  } catch (error) {
    console.error('Failed to close the database connection:', error);
    throw new Error('Failed to close the database connection');
  }
}