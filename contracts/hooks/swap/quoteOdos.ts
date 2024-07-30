export async function fetchQuote(params: any, quoteUrl: any, tag: any) {
    try {
      const response = await fetch(quoteUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(params),
      });
  
      const data = await response.json();
  
      if (response.ok) {
        return {
          ...data,
        };
      } else {
        throw new Error(`Error: ${data.error || response.statusText}`);
      }
    } catch (error) {
      console.error(`Failed to get quote: ${error}`);
      return undefined;
    }
  }

  export async function assembleQuote(userAddr: string, pathId: string, assembleUrl: string, simulate = false, contractAdress: string) {
    try {
      const response = await fetch(assembleUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userAddr,
          pathId,
          simulate,
          contractAdress,
        }),
      });
  
      if (!response.ok) {
        const errorText = await response.text();  // Get error response text
        throw new Error(`Error: ${errorText}`);
      }
  
      const data = await response.json();
      return data.transaction;
    } catch (error) {
      console.error(`Failed to assemble quote: ${error }`);
      return undefined;
    }
  }
  