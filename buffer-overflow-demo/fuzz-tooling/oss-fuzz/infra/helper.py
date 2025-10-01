#!/usr/bin/env python3
"""
Mock OSS-Fuzz helper.py script for testing
This is a minimal version that satisfies the patcher's requirements
"""
import sys
import os
import subprocess
import argparse

def build_image(args):
    """Mock build_image - does nothing but return success"""
    print(f"Mock: Skipping Docker image build")
    return 0

def build_fuzzers(project_name, src_dir=None, architecture=None, engine=None, sanitizer=None):
    """Build the fuzzers for the project"""
    print(f"Building fuzzers for {project_name}")

    # Use provided source directory or default to projects/{project_name}
    if src_dir:
        print(f"Using source directory: {src_dir}")

    # Check if we need to save the container (for CodeQuery)
    container_name = os.environ.get('OSS_FUZZ_SAVE_CONTAINERS_NAME')
    if container_name:
        print(f"Mock: Creating saved container {container_name}")
        return build_fuzzers_with_container(project_name, src_dir, container_name)

    # Set up environment variables for the build
    env = os.environ.copy()
    env.setdefault('CC', 'clang')
    env.setdefault('CXX', 'clang++')
    env.setdefault('CFLAGS', '-g -O1 -fno-omit-frame-pointer')
    env.setdefault('CXXFLAGS', '-g -O1 -fno-omit-frame-pointer')
    env.setdefault('LIB_FUZZING_ENGINE', '-fsanitize=fuzzer')

    # Set output directories
    base_dir = os.getcwd()
    env.setdefault('OUT', os.path.join(base_dir, 'out'))
    env.setdefault('WORK', os.path.join(base_dir, 'work'))

    # Set SRC to the provided source directory or the project directory
    if src_dir and os.path.isabs(src_dir):
        env['SRC'] = src_dir
    else:
        env.setdefault('SRC', os.path.join(base_dir, 'projects', project_name))

    # Create output directories
    os.makedirs(env['OUT'], exist_ok=True)
    os.makedirs(env['WORK'], exist_ok=True)

    # Look for build.sh in the project directory
    project_dir = os.path.join(base_dir, 'projects', project_name)
    build_script = os.path.join(project_dir, 'build.sh')

    if os.path.exists(build_script):
        print(f"Running build script: {build_script}")
        result = subprocess.run(['bash', build_script], env=env, cwd=base_dir)
        return result.returncode
    else:
        print(f"Error: Build script not found at {build_script}")
        return 1

def build_fuzzers_with_container(project_name, src_dir, container_name):
    """Build fuzzers and create a Docker container with the source code"""
    # Find the task root directory
    base_dir = os.getcwd()
    task_root = os.path.abspath(os.path.join(base_dir, '../..'))

    # Create a simple Dockerfile that copies the source
    dockerfile_content = f"""FROM scratch
COPY . /src/
"""

    dockerfile_path = os.path.join(base_dir, 'Dockerfile.temp')
    with open(dockerfile_path, 'w') as f:
        f.write(dockerfile_content)

    try:
        # Build a minimal Docker image with the source code
        print(f"Creating Docker container with source code...")

        # Use docker create instead of docker run to create a stopped container
        # This mimics OSS-Fuzz's save container behavior
        result = subprocess.run([
            'docker', 'create',
            '--name', container_name,
            'busybox:latest',  # Use busybox as a lightweight base
            'true'  # Command that does nothing
        ], capture_output=True, text=True)

        if result.returncode != 0:
            print(f"Error creating container: {result.stderr}")
            return 1

        # Copy the source directory into the container at /src
        src_path = os.path.join(task_root, 'src')
        if os.path.exists(src_path):
            result = subprocess.run([
                'docker', 'cp',
                src_path,
                f'{container_name}:/'
            ], capture_output=True, text=True)

            if result.returncode != 0:
                print(f"Error copying source to container: {result.stderr}")
                subprocess.run(['docker', 'rm', container_name], capture_output=True)
                return 1

        print(f"Successfully created container {container_name} with source code")
        return 0

    finally:
        if os.path.exists(dockerfile_path):
            os.remove(dockerfile_path)

def run_fuzzer(project_name, fuzzer_name, *args):
    """Run a fuzzer"""
    print(f"Running fuzzer {fuzzer_name} for {project_name}")
    out_dir = os.path.join(os.getcwd(), 'out')
    fuzzer_path = os.path.join(out_dir, fuzzer_name)

    if not os.path.exists(fuzzer_path):
        print(f"Error: Fuzzer not found at {fuzzer_path}")
        return 1

    return subprocess.run([fuzzer_path] + list(args)).returncode

def check_build(project_name):
    """Check if build artifacts exist"""
    out_dir = os.path.join(os.getcwd(), 'out')
    if os.path.exists(out_dir) and os.listdir(out_dir):
        print(f"Build artifacts found in {out_dir}")
        return 0
    else:
        print(f"No build artifacts found in {out_dir}")
        return 1

def reproduce(project_name, fuzzer_name, *args):
    """Reproduce a crash with a test case"""
    print(f"Reproducing crash for {fuzzer_name} in {project_name}")
    print(f"Args: {args}")
    out_dir = os.path.join(os.getcwd(), 'out')
    fuzzer_path = os.path.join(out_dir, fuzzer_name)

    if not os.path.exists(fuzzer_path):
        print(f"Error: Fuzzer not found at {fuzzer_path}")
        return 1

    cmd = [fuzzer_path] + list(args)
    print(f"Running command: {cmd}")
    return subprocess.run(cmd).returncode

def main():
    parser = argparse.ArgumentParser(description='OSS-Fuzz helper script')
    parser.add_argument('command', choices=['build_image', 'build_fuzzers', 'run_fuzzer', 'check_build', 'reproduce'])
    parser.add_argument('project', help='Project name')

    # Optional arguments
    parser.add_argument('--pull', action='store_true', help='Pull latest base image')
    parser.add_argument('--no-pull', dest='pull', action='store_false', help='Do not pull latest base image')
    parser.add_argument('--cache', action='store_true', help='Use build cache')
    parser.add_argument('--no-cache', dest='cache', action='store_false', help='Do not use build cache')
    parser.add_argument('--architecture', help='Target architecture')
    parser.add_argument('--engine', help='Fuzzing engine')
    parser.add_argument('--sanitizer', help='Sanitizer to use')
    parser.add_argument('args', nargs='*', help='Additional arguments')

    args = parser.parse_args()

    if args.command == 'build_image':
        return build_image(args)
    elif args.command == 'build_fuzzers':
        # For build_fuzzers, first arg is src_dir
        src_dir = args.args[0] if args.args else None
        return build_fuzzers(args.project, src_dir, args.architecture, args.engine, args.sanitizer)
    elif args.command == 'run_fuzzer':
        if not args.args:
            print("Error: Fuzzer name required")
            return 1
        return run_fuzzer(args.project, args.args[0], *args.args[1:])
    elif args.command == 'check_build':
        return check_build(args.project)
    elif args.command == 'reproduce':
        if not args.args:
            print("Error: Fuzzer name required")
            return 1
        return reproduce(args.project, args.args[0], *args.args[1:])

    return 0

if __name__ == '__main__':
    sys.exit(main())