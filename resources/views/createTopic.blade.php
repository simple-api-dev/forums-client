<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Create Topic</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>
<body>
<div class="container mt-3 mb-3">

    <h3>Create New Topic</h3>
    <form action="http://127.0.0.1:8000/storeTopic" method="POST" enctype="multipart/form-data">
        @csrf

        <input type="hidden" name="id" value="{{$id}}">

        <div class="form-group">
            <label for="title">Title</label>
            <input type="text" class="form-control" name="title" id="title">
        </div>

        <div class="form-group">
            <label for="body">Body</label>
            <input type="text" class="form-control" name="body" id="body">
        </div>

        <div class="form-group">
            <label for="type">Type</label>
            <select class="form-control" name="type" id="type">
                <option value="Post">Post</option>
                <option value="Video">Video</option>
                <option value="Url">Url</option>
                <option value="Image">Image</option>
            </select>
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

        <div class="form-group">
            <label for="tags">Tags</label>
            <input type="text" class="form-control" name="tags" id="tags">
        </div>

        <input type="reset" name="reset" value="Reset" class="btn btn-dark">
        <input type="submit" name="submit" value="Submit" class="btn btn-dark">

    </form>
</div>
</body>

</html>
