function handler(event) {
    let req = event.request;

    if(req.uri === '/minesweeper' || req.uri === '/minesweeper/') {
        req.uri = '/minesweeper/index.html';
        return req;
    }
    if (req.uri.startsWith('/minesweeper/')) {
        const lastSegment = req.uri.slice(req.uri.lastIndexOf('/') + 1);
        if (lastSegment.indexOf('.') === -1) {
            req.uri = '/minesweeper/index.html';
        }
    }

    return req;
}