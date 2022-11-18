<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Create Rule</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>
<body>
<div class="container mt-3 mb-3">

    <h3>Create New Rule</h3>
    <form action="http://127.0.0.1:8000/storeRule" method="POST" enctype="multipart/form-data">
        @csrf

        <input type="hidden" name="id" value="{{$id}}">

        <div class="form-group">
            <label for="body">Body</label>
            <input type="text" class="form-control" name="body" id="body">
        </div>

        <div class="form-group">
            <label for="status">Status</label>
            <select class="form-control" name="status" id="status">
                <option value="Active">Active</option>
                <option value="Disabled">Disabled</option>
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
