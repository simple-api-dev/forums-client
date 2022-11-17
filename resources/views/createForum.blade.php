<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Create Forum</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>
<body>
<div class="container mt-3 mb-3">

    <h3>Create New Forum</h3>
    <form action="http://127.0.0.1:8000/storeForum" method="POST" enctype="multipart/form-data">
        @csrf

        <div class="form-group">
            <label for="title">Title</label>
            <input type="text" class="form-control" name="title" id="title">
        </div>

        <div class="form-group">
            <label for="body">Body</label>
            <input type="text" class="form-control" name="body" id="body">
        </div>

        <div class="form-group">
            <label for="status">Status</label>
            <select class="form-control" name="status" id="status">
                <option value="Active">Active</option>
                <option value="Draft">Draft</option>
                <option value="Pending Review">Pending Review</option>
                <option value="Locked">Locked</option>
            </select>
        </div>

        <div class="form-group">
            <label for="author_id">Author Id</label>
            <input type="text" class="form-control" name="author_id" id="author_id">
        </div>

        <input type="reset" name="reset" value="Reset" class="btn btn-dark">
        <input type="submit" name="submit" value="Submit" class="btn btn-dark">

    </form>
</div>
</body>

</html>
